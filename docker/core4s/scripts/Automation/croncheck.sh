#!bin/bash
#Script for automatic check of cronjobs
#$1 contains name of the cronjob
#$2 contains variable to show cronjob failure/success
#usage: replace name and cronjob:
###################cronjob && sh /core4s/scripts/Automation/croncheck.sh NAME SUCCESS || sh /core4s/scripts/Automation/croncheck.sh NAME FAILURE
#
#########Changable Variables################
loglocation="/var/log/cronchecker"
logfile="$loglocation/cronjobchecker_$1.json"
tempfile="$loglocation/cronjobchecker_$1.json.tmp"
email_reciever="box@4sconsult.de"
vulnwhisp_log="$loglocation/vulnwhisp.log"
########################################
timestamp=$(date +%d-%m-%Y_%H-%M-%S)
initialize()
{
#check if logfile - file that saves all cronjob information - exists, else creates it
if [ ! -f "$logfile" ];then
        if [ ! -d "$loglocation" ];then
                mkdir $loglocation
        fi
        {
        echo '{'
        echo '  "cronjobs": []'
                echo '}'
        } >> "$logfile"
fi
#check if current cronjob already is present in file and create if not
jq -e '.cronjobs[] | select(.title == "'$1'") ' "$logfile"  > /dev/null
if [ $? -ne 0 ];then
        #executed when key is found in the previous jq call - creates new entry for cronjob, saves it to temp file, moves to new file and removes temp file
        jq '.cronjobs += [{"title": "'$1'", "run_last": "", "fail_last": "", "last_scheduled_run": "", "run_last_prev": "", "fail_last_prev": "", "alert_ctr": "0"}]' "$logfile" > "$tempfile" && mv -f "$tempfile" "$logfile"
fi
}
###
alert()
{
        #TODO: send email with boxname and error code(name of the cronjob, maybe also include output of sudo grep CRON /var/log/syslog)
        if [ $1 = "unexpected_error" ];then
                echo "Unerwarteter Fehler beim Ausführen vom Cronjobchecker Script\nInput Cronjob: $1" | /core4s/scripts/sendmail.sh $email_reciever "Cronjob Skript endetete mit unerwartetem Fehler"
        else
                #try the job again, mark error but do not send email
                last_success=$(jq -r '.cronjobs[] | select(.title == "'$1'")| .run_last' "$logfile")
                last_fail=$(jq -r '.cronjobs[] | select(.title == "'$1'")| .fail_last_prev' "$logfile")
				loginfo=$(sudo grep "$1" /var/log/syslog)
                echo "Fehler beim Ausführen von Cronjob $1\nFehler trat um $last_fail auf!\nLetzte Erfolgreiche Ausführung war um: $last_success\nLogs:\n\n$loginfo" | /core4s/scripts/sendmail.sh $email_reciever "Cronjob Fehler für $1"
        fi
}
###
insert_json()
{
        #function to insert new values into the json document
        #$1 = $1 =cronjob name
        #$2 = variable to change
        #$3 = what variable should be changed to
        jq '(.cronjobs[] | select(.title == "'$1'").'$2') = "'$3'"' "$logfile" > "$tempfile" && mv -f "$tempfile" "$logfile"

}
###
update_values()
{
        if [ $2 = "SUCCESS" ];then
                #scheduled run time insert
                insert_json $1 last_scheduled_run $timestamp
                #update previous run value to current one and change current one
                tmp=$(jq -r '.cronjobs[] | select(.title == "'$1'")| .run_last' "$logfile")
                insert_json $1 run_last_prev $tmp
                insert_json $1 run_last $timestamp
        elif [ $2 = "FAILURE" ];then
                #scheduled run time insert
                insert_json $1 last_scheduled_run $timestamp
                #update previous fail value to current one and change current one
                tmp=$(jq -r '.cronjobs[] | select(.title == "'$1'")| .fail_last' "$logfile")
                insert_json $1 fail_last_prev $tmp
                insert_json $1 fail_last $timestamp
                #increment alert ctr
                alertctr=$(jq -r '.cronjobs[] | select(.title == "'$1'")| .alert_ctr' "$logfile")
                alertctr=$((alertctr+1))
                insert_json $1 alert_ctr $alertctr
########EMAIL ALERTS DISABLED FOR NOW###########
                #send alert
#                alert $1
#        else
#                #something wrent wrong with the script send corresponding alert
#                alert unexpected_error
        fi
}
###
###Main
initialize $1
#special case: vulnwhisp record collector, which fails without data in database
if [ $1 = "vulnwhisp" ] && [ -f "$vulnwhisp_log" ];then
  #check if created logfile contains empty database
  #which reports as: referenced before assigned
    if grep -q "ERROR: local variable 'report' referenced before assignment" "$vulnwhisp_log";then
      #Failed becaues empty database; Interpret as SUCCESS
      update_values $1 SUCCESS
    else
      #Really Failed
      update_values $1 $2
    fi
  #Get rid of logging file
    rm "$vulnwhisp_log"
#special case: openvas record collector, which fails without data in database
else
# if not special case, then proceed as usual
  update_values $1 $2
fi
#remove tempfile if exist
if [ -f "$tempfile" ];then

        rm "$tempfile"
fi
