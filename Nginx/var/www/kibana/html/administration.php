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

<?php

if(isset($_GET['update'])) {
exec("chmod 777 /var/www/kibana/html/update/update -R");
exec("rm /var/www/kibana/html/update/updateStatus.log");
$TAG=$_GET["update"];
exec("sed -i '3s/.*$/$TAG=\"'$TAG'\"/g' /home/amadmin/box4s/BOX4s-main/update.sh");
//Update.sh muss per Installscript und UpdateScript www-data gehören und +x bekommen     
exec('sudo /home/amadmin/box4s/BOX4s-main/update.sh >/dev/null &2>/dev/null &');
//exec("chmod 777 /var/www/kibana/html/update/ -R");
}
?>


<script>

function sleep(milliseconds) {
  return new Promise(resolve => setTimeout(resolve, milliseconds))
}

async function openUpdateModal() {
$('.ui.modal').modal('show');
var updateStatus="";
do {
	// Iframe dynamicContent.php wird alle 2 sec neu aufgerufen und der Status geupdatet
	var iframe = document.getElementById('dynamic');
	updateStatus=iframe.contentWindow.consoleEcho;
	await sleep(1000);
	iframe.src="dynamicContent.php";
	await sleep(1000);
	console.log(updateStatus); 
	document.getElementById("updateStatus").innerHTML = updateStatus;
} while (updateStatus.match("Update abgeschlossen") != "Update abgeschlossen");
// Nachdem Update abgeschlossen im Status erscheit wird die Seite freigegeben und die Elemente entsprechend mit neuem Content versehen
document.getElementById("statusUpdateMessage").innerHTML = "Das Update ist abgeschlossen";
document.getElementById("updateHeader").innerHTML = "Sie können das Fenster jetzt schließen";
document.getElementById("dimmer").setAttribute('class','ui inverted dimmer');

}
</script>

<?php
// Logik für die Anzeige der bereits installierten und installierbaren Versionen. CurVer ist die aktuell installierte Version.
exec("curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2Fbox4s/repository/tags --header 'PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC' | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))'",$tagCount);
exec("tail /home/amadmin/box4s/BOX4s-main/VERSION",$curVer);
for($ctr=0;$ctr<$tagCount[0];$ctr++){
	exec('curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2Fbox4s/repository/tags --header "PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC" | python3 -c "import sys, json; print(json.load(sys.stdin)['.$ctr.'][\'name\'])"',$tags[$ctr]);
}
?>
</head>


<?php
if(isset($_GET['update'])) { echo('<body onload="openUpdateModal()">');}
else{ echo("<body>"); }
?>
<iframe src="dynamicContent.php" name="dynamic" width="0px" height="0px" id="dynamic"> </iframe>

<div class="ui modal">
  <div id="updateHeader" class="header">Bitte lassen Sie das Fenster geöffnet</div>
  <div class="content">
    <p id="updateContent"></p>
    <p id="statusUpdateMessage">Der Updatevorgang läuft</p>
   <div class="ui segment">
  <div class="ui active inverted dimmer" id="dimmer">
    <div class="ui text loader">Loading</div>
  </div>
  <p id="updateStatus"><br> </p>
</div></div></div>

<div class="ui divider"></div>
<div class="ui grid padded  ">
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
if ($ctr<$tagCount[0]){
if ($curVer[0]==$tags[$ctr+1][0]){
	echo('<form method="get" action="administration.php">');
	
	echo('<input type="hidden" value="'.$tags[$ctr][0].'" name="update">');
	echo('<button class="ui button" type="submit">Update</button>');
	echo('</form>');
}elseif ($curVer[0]==$tags[$ctr][0]){
	echo('<i class="large green checkmark icon"></i>');
}elseif ($curVer[0]> $tags[$ctr][0]){
	echo('<i class="large green checkmark icon"></i>');
}elseif ($curVer[0]< $tags[$ctr][0]){
echo('<i class="large red close icon"></i>');
}
echo ('</td>');
}
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


