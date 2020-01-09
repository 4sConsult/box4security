<html>
<head>
<link rel="stylesheet" type="text/css" href="semantic/dist/semantic.min.css">
<script
  src="https://code.jquery.com/jquery-3.1.1.min.js"
  integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
  crossorigin="anonymous"></script>
<script src="semantic/dist/semantic.min.js"></script>

<?php
$dbconn = pg_connect("host=localhost dbname=box4S_db user=postgres password=zgJnwauCAsHrR6JB")
   or die('Verbindungsaufbau fehlgeschlagen: ' . pg_last_error());
?>
</head>
<body>
<!-- Äußere Spalten um die beiden Filtertypen zu trennen -->
<div class="ui divider"></div>
<div class="ui grid padded">
<div class="two wide column " >
<table class="ui celled table">
<h3> Kernel Filter </h3>
  <thead>
    <tr><th>Source IP</th>
    <th>Source Port</th>
    <th>Destination IP</th>
<th>Destination Port</th>
<th>IP Protokoll</th>
  </tr></thead>
  <tbody>
<?php 
$query ="SELECT * from blocks_by_bpffilter";
        $results = pg_query($query);
        $filterrule="";
        while ($row = pg_fetch_array($results)){
	?>
     <tr>
	     <td> <?php echo $row['src_ip'];?> </td>
      <td><?php echo $row['src_port'];?></td>
      <td><?php echo $row['dst_ip'];?></td>
<td><?php echo $row['dst_port'];?></td>
<td><?php echo $row['proto'];?></td>

    </tr>	
<?php } ?>

</div> 
<div class="two wide column">
</div>
</body>
</html>
