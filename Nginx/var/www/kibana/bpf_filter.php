<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" type="text/css" href="semantic/dist/semantic.min.css">
<script
  src="https://code.jquery.com/jquery-3.1.1.min.js"
  integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
  crossorigin="anonymous"></script>
<script src="semantic/dist/semantic.min.js"></script>

<?php
/*
error_reporting(E_ERROR | E_WARNING | E_PARSE | E_NOTICE);
if ($send_bpf_filter==true){
	$inhalt="TESTETETETETE";
$file ="/usr/libexec/suricata/ebpf/bypass_filter.bpf.test";
$returncode = file_put_contents($file, $inhalt, FILE_APPEND | LOCK_EX);
if is_writable ( string $file ) == false {
	echo "Datei konte nicht geschrieben werden";
} else {
	echo "Datei wurde geschrieben";
}
fclose ($handle);
}
 */


$src_ip = $_GET['src_ip'];
$src_port = $_GET['src_port'];
$dest_ip = $_GET['dest_ip'];
$dest_port = $_GET['dest_port'];
$proto = $_GET['proto'];
$send_bpf_filter = true;
?>
<?php if(isset ($_GET['bpf_filter'])) echo "<script type='text/javascript'> $('.ui.modal').modal('show'); </script>" ?>
<script> 

function enable_bpf_config() {
$('.ui.modal')
  .modal('show')
;
}
</script>
</head>
 <body onload="enable_bpf_config()"> 
<-- <body> -->
<!-- <button onclick="enable_bpf_config()">Click me</button>  -->
<form class="ui modal form">
  
<!-- Lade bestehende Blocks -->

<div class="ui six column doubling stackable grid container with=300px">

 
  <div class="column">
    <p>Source IP</p>
    <div class="ui input">
		<input type="text" placeholder="<?php echo $src_ip; ?>">
	</div>
  </div>
  <div class="column">
    <p>Source Port</p>
    <div class="ui input">
		<input type="text" placeholder="<?php echo $src_port; ?>">
	</div>
  </div>
  <div class="column">
    <p>Destination IP</p>
    <div class="ui input">
		<input type="text" placeholder="<?php echo $dest_ip; ?>">
	</div>
  </div>	
  <div class="column">
    <p>Destination Port</p>
    <div class="ui input">
		<input type="text" placeholder="<?php echo $dest_port; ?>">
	</div>
  </div>
  <div class="column">
    <p>Protocol</p>
	<div class="ui right labeled input">
	<input type="text" placeholder="<?php echo $proto; ?>">
  <div class="ui dropdown label">
    <div class="text"><?php echo $proto; ?></div>
    <i class="dropdown icon"></i>
    <div class="menu">
      <div class="item">udp</div>
      <div class="item">icmp</div>
    </div>
  </div>
  
</div>
   
</div>
<div class="row">
 <button class="ui button" type="submit">Submit</button>
</div>
</div>

</form>

</body>
	<footer>
        </footer>

</html>
