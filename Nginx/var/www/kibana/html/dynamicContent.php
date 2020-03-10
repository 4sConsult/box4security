<html>
<head>

<script>
<?php
exec("tail -n15 /var/www/kibana/html/update/updateStatus.log | sed 's/\"//g' | sed \"s/'//g\"",$update);
?>
var consoleEcho ="<?= implode('<br>',$update); ?>";
<?php if (isset($_GET['pid'])) {
  // see: https://www.php.net/manual/de/function.exec.php#88704
  $pid = escapeshellarg($_GET['pid']);
  exec('ps -p '.$pid,$op);
  if (!isset($op[1])):?>
    var updateRunning = false;
  <?php else: ?>
    var updateRunning = true;
  <?php endif;
} else {?>
  var updateRunning = true;
  <?php
}?>
</script>
</head>
</html>
