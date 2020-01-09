<html>
<head>
<script>
<?php
exec("tail -10 /var/www/kibana/html/update/updateStatus.log | sed 's/\"//g' | sed \"s/'//g\"",$update);
//print_r( $update);
?>
var consoleEcho ="<?php echo(implode('<br>',$update));?>";
</script>
</head>
</html>

