<html>
<head>
<script>
<?php
exec("tail -10 /var/www/kibana/html/update/updateStatus.log",$update);
?>
//updateUpdateStatus();
        var consoleEcho ="<?php echo(implode('<br>',$update));?>";
      //  document.getElementById("updateStatus").innerHTML = updateStatus;
      //  console.log(consoleEcho);

//}while (updateStatus.match("Update abgeschlossen")!="Update abgeschlossen");
//document.getElementById("statusUpdateMessage").innerHTML = "Das Update ist abgeschlossen";
//document.getElementById("dimmer").setAttribute('class','ui inverted dimmer');


</script>
</head>
</html>

