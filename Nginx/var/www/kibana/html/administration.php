<html>
<head>
<link rel="stylesheet" type="text/css" href="semantic/dist/semantic.min.css">
<script
  src="https://code.jquery.com/jquery-3.1.1.min.js"
  integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
  crossorigin="anonymous"></script>
<script src="semantic/dist/semantic.min.js"></script>
<?php

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
?>
<script>
var updateStatus="";
function sleep(milliseconds) {
  return new Promise(resolve => setTimeout(resolve, milliseconds))
}

function updateUpdateStatus() {
<?php 
exec("tail -10 /var/www/kibana/html/update/updateStatus.log",$update);
?>
	updateStatus ="<?php echo(implode('<br>',$update));?>";
	document.getElementById("updateStatus").innerHTML = updateStatus;
}


async function openUpdateModal() {
$('.ui.modal')
  .modal('show')
;
	
<?php
if(isset($_POST['update'])) {
exec("rm /var/www/kibana/html/update/updateStatus.log");
$TAG=$POST["update"];
exec("sed -i '3s/.*$/$TAG=\"'$TAG'\"/g' /home/amadmin/box4s/BOX4S-main/update.sh");
}
?>

var updateStatus="";
do {
	// Iframe dynamicContent.php wird alle 2 sec neu aufgerufen und der Status geupdatet
	var iframe = document.getElementById('dynamic');
	  await sleep(1000);
	  iframe.src="dynamicContent.php";
	  await sleep(1000);
	 console.log(iframe.contentWindow.consoleEcho); 
	 updateStatus=iframe.contentWindow.consoleEcho;
	document.getElementById("updateStatus").innerHTML = updateStatus;
}while (updateStatus.match("Update abgeschlossen")!="Update abgeschlossen");
// Nachdem Update abgeschlossen im Status erscheit wird die Seite freigegeben und die Elemente entsprechend mit neuem Content versehen
document.getElementById("statusUpdateMessage").innerHTML = "Das Update ist abgeschlossen";
document.getElementById("updateHeader").innerHTML = "Sie können das Fenster jetzt schließen";
document.getElementById("dimmer").setAttribute('class','ui inverted dimmer');

}
</script>


<div class="ui modal">
  <div id="updateHeader" class="header">Bitte lassen Sie das Fenster geöffnet</div>
  <div class="content">
    <p id="updateContent"></p>
    <p id="statusUpdateMessage">Der Updatevorgang läuft</p>
   <div class="ui segment">
  <div class="ui active inverted dimmer" id="dimmer">
    <div class="ui text loader">Loading</div>
  </div>
<iframe name="dynamic" width="0px" height="0px" id="dynamic"> </iframe>

  <p id="updateStatus"><br> </p> 
<?php 

//exec("tail -10 /var/www/kibana/html/update/updateStatus.log",$update);
//exec("ls -hl",$update);
//sleep(1); 
//echo(implode("<br>",$update));
//print_r($update);
//echo("Test");
?>

</div>
<?php
error_reporting(E_ALL & ~E_NOTICE);
if(isset($_POST['update'])) {
       //Update.sh muss per Installscript und UpdateScript www-data gehören und +x bekommen	
	passthru('/home/amadmin/box4s/BOX4s-main/update.sh '.$_POST['update'].'&',$return);
}
?> 
  </div>
</div>
</div>
<?php
// Logik für die Anzeige der bereits installierten und installierbaren Versionen. CurVer ist die aktuell installierte Version.
exec("curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2FBOX4security%2Fmain/repository/tags --header 'PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC' | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))'",$curTag);
exec("curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2FBOX4security%2Fmain/repository/tags --header 'PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC' | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))'",$tagCount);
exec("tail /home/amadmin/box4s/BOX4s-main/VERSION",$curVer);
exec('curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2FBOX4security%2Fmain/repository/tags --header "PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC" | python3 -c "import sys, json; print(json.load(sys.stdin)['.$ctr.'][\'name\'])"',$curTag);
for($ctr=0;$ctr<$tagCount[0];$ctr++){
	exec('curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2FBOX4security%2Fmain/repository/tags --header "PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC" | python3 -c "import sys, json; print(json.load(sys.stdin)['.$ctr.'][\'name\'])"',$tags[$ctr]);
}
?>
</head>
<?php
if(isset($_POST['update'])) { echo('<body onload="openUpdateModal()">');}
else{ echo("<body>"); }
?>
<div class="ui grid">
<div class="two wide column">
<p> Verfügbare Updates </p>
<div class="ui container">
<table class="ui celled structured table">
  <thead>
    <tr>
      <th with="50px">Version</th>
      <th>Update</th>
    </tr>
</thead>
<tbody>

<?php
for($ctr=0;$ctr<$tagCount[0];$ctr++) {
echo('<tr>');
echo('<td class="right aligned">');
echo($tags[$ctr][0]);
echo('</td><td>');
if ($curVer[0]==$tags[$ctr+1][0]){
	echo('<form method="post" action="administration.php">');
	
	echo('<input type="hidden" value="'.$tags[$ctr][0].'" name="update">');
	echo('<button class="ui button" type="submit">Update</button>');
	echo('</form>');
}
elseif ($curVer[0]==$tags[$ctr][0]){
	echo('<i class="large green checkmark icon"></i>');
}
elseif ($curVer[0]> $tags[$ctr][0]){
	echo('<i class="large green checkmark icon"></i>');
}elseif ($curVer[0]< $tags[$ctr][0]){
echo('<i class="large red close icon"></i>');
}
echo ('</td>');
}
?>

</tr>
  </tbody>
</table>
</div>
</div>
<div class="four wide column">
</div>
</div>
</body>
</html>

