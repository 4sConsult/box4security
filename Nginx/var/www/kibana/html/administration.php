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
$TAG=escapeshellcmd($TAG);
exec("sed -i '3s/.*$/$TAG=\"'$TAG'\"/g' /home/amadmin/box4s/BOX4s-main/update.sh");
//Update.sh muss per Installscript und UpdateScript www-data gehören und +x bekommen
// $updatePid holds the pid of update.sh
exec('sudo /home/amadmin/box4s/BOX4s-main/update.sh >/dev/null 2>&1 & echo $!', $updatePid);
//exec("chmod 777 /var/www/kibana/html/update/ -R");
}
?>


<script>

function sleep(milliseconds) {
  return new Promise(resolve => setTimeout(resolve, milliseconds))
}

async function openUpdateModal() {
$('.ui.modal').modal('show');
var consoleEcho="";
var updateRunning=true;
do {
	// Iframe dynamicContent.php wird alle 2 sec neu aufgerufen und der Status geupdatet
	var iframe = document.getElementById('dynamic');
	await sleep(1000);
	iframe.src="/dynamicContent.php?pid="+<?=$updatePid[0]?>;
  consoleEcho=iframe.contentWindow.consoleEcho;
  updateRunning=iframe.contentWindow.updateRunning;
  console.log(updateRunning)
	await sleep(1000);
	console.log(consoleEcho);
	document.getElementById("consoleEcho").innerHTML = consoleEcho;
} while (updateRunning);
// Nachdem Update abgeschlossen im Status erscheit wird die Seite freigegeben und die Elemente entsprechend mit neuem Content versehen
document.getElementById("statusUpdateMessage").innerHTML = "Das Update ist abgeschlossen.";
document.getElementById("statusUpdateMessageLong").innerHTML = "Sie können das Fenster jetzt schließen.";
document.getElementById("dimmer").setAttribute('class','ui inverted dimmer');
$('#circle').attr('class','large icon green checkmark');

}
</script>

<?php
// Get TAG Count
exec("curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags --header 'PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6' | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))'",$tagCount);
// exec("curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2Fbox4s/repository/tags --header 'PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC' | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))'",$tagCount);

// CurVer ist die aktuell installierte Version.
exec("tail /home/amadmin/VERSION",$curVer);
for($ctr=0;$ctr<$tagCount[0];$ctr++){
  // get TAG Names
	exec('curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | python3 -c "import sys, json; print(json.load(sys.stdin)['.$ctr.'][\'name\'])"',$tags[$ctr]);
  // exec('curl -s https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2Fbox4s/repository/tags --header "PRIVATE-TOKEN: Lmp3tZkURptSjWsn7tyC" | python3 -c "import sys, json; print(json.load(sys.stdin)['.$ctr.'][\'name\'])"',$tags[$ctr]);
}
?>
</head>


<?php if (isset($_GET['update'])): ?>
  <body onload="openUpdateModal()">
<?php else: ?>
  <body>
<?php endif; ?>
<iframe src="dynamicContent.php" name="dynamic" width="0px" height="0px" id="dynamic"> </iframe>

<div class="ui modal">
  <div class="header">Update</div>
  <div class="content">
    <p id="updateContent"></p>
    <div class="ui icon message">
      <i id="circle" class="notched circle loading icon"></i>
      <div class="content">
        <div id="statusUpdateMessage" class="header">
          Der Updatevorgang läuft..
        </div>
        <p id="statusUpdateMessageLong">Das System wird aktualisiert. Bitte lassen Sie das Fenster geöffnet.</p>
      </div>
    </div>
   <div class="ui segment">
  <div class="ui active inverted dimmer" id="dimmer">
  </div>
  <p id="consoleEcho"><br> </p>
</div></div></div>

<div class="ui grid padded">
<div class="two wide column">
<p> Verfügbare Updates </p>
<div class="ui container">
<table class="ui celled structured table">
  <thead>
    <tr>
      <th>Version</th>
      <th>Update</th>
    </tr>
</thead>
<tbody>
<?php
$ctr = 0;
?>
<tr>
  <td class="right aligned"><?= $tags[$ctr][0] ?></td>
  <td>
<?php if ($curVer[0] < $tags[$ctr][0]): ?>
    <form style="margin:0;" class="ui form" method="get" action="administration.php">
      <input type="hidden" value="<?= $tags[$ctr][0] ?>" name="update">
      <button class="ui button" type="submit">Update</button>
    </form>
<?php else: ?>
  <i class="large green checkmark icon"></i>
<?php endif; ?>
</td>
</tr>
<?php
if(++$ctr < $tagCount) {
  // Rest of the tags if more available
for(;$ctr<$tagCount[0];$ctr++) {
?>
<tr>
<td class="right aligned">
  <?php if ($curVer[0] == $tags[$ctr][0]): ?>
    <b><?= $tags[$ctr][0] ?></b>
  <?php else: ?>
    <?= $tags[$ctr][0] ?>
  <?php endif; ?>
</td>
<td>
<?php if ($curVer[0] >= $tags[$ctr][0]): ?>
  <i class="large green checkmark icon"></i>
<?php else: ?>
  <i class="large angle double up icon"></i>
<?php endif; ?>
</td>
</tr>
<?php
  }
}
?>
</tbody>
</table>
</div>
</div>
</div>
</body>
</html>
