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
if($_GET["src_ip"]!=""){  $src_ip=$_GET["src_ip"]; } else { $src_ip="0.0.0.0"; }
if($_GET["src_port"]!=""){  $src_port=$_GET["src_port"]; } else { $src_port="0"; }
if($_GET["dest_ip"]!=""){  $dest_ip=$_GET["dest_ip"]; } else { $dest_ip="0.0.0.0"; }
if($_GET["dest_port"]!=""){  $dest_port=$_GET["dest_port"]; } else { $dest_port="0"; }
if($_GET["proto"]!=""){  $proto=$_GET["proto"]; } else { $proto=""; }
if(isset($_GET["signature_id"])) { if ($_GET["signature_id"]!=""){  $signature_id=$_GET["signature_id"]; } else { $signature_id=""; }}
if(isset($_GET["signature"])){ if ($_GET["signature"]!=""){  $signature=$_GET["signature"]; } else { $signature=""; }}




if ($_GET['delete']==1){
  pg_prepare($dbconn, "query", 'DELETE FROM blocks_by_bpffilter WHERE
    (
      src_ip = $1 AND
      src_port = $2 AND
      dst_ip = $3 AND
      dst_port = $4 AND
      proto = $5
    )
    ');
   $result = pg_execute($dbconn, "query", array($src_id, $src_port, $dest_ip, $dest_port, $proto));
 //TODO make function for reusage
 $file="/var/www/kibana/ebpf/bypass_filter.bpf";
	//unlink($file);
	$query ="SELECT * from blocks_by_bpffilter";
	$results = pg_query($query);
	$filterrule="";
	while ($row = pg_fetch_array($results)){
	$filterrule.="!(";
	if ($row['src_ip']!='0.0.0.0'){
		$filterrule.="src host ".$row['src_ip'];}
	if ($row['src_port']!='0'){
		if ($row['src_ip']!='0.0.0.0'){ $filterrule.=" && ";}
		$filterrule.="src port ".$row['src_port'];}
        if ($row['dst_ip']!='0.0.0.0'){
                if ($row['src_ip']!='0.0.0.0' || $row['src_port']!=0){ $filterrule.=" && ";}
                $filterrule.="dst host ".$row['dst_ip'];}
        if ($row['dst_port']!='0'){
                if ($row['src_ip']!='0.0.0.0' || $row['src_port']!=0 || $row['dst_ip']!='0.0.0.0'){ $filterrule.=" && ";}
                $filterrule.="dst port ".$row['dst_port'];}
	      if ($row['proto']!=''){
                if ($row['src_ip']!='0.0.0.0' || $row['src_port']!=0 || $row['dst_ip']!='0.0.0.0' || $row['dst_port']!=0){ $filterrule.=" && ";}
		$filterrule.="ip proto \\".$row['proto'];}
	$filterrule .=") &&\r\n";

	$filterrule = substr($filterrule, 0, -4);
}
    file_put_contents($file, $filterrule);
	exec('sudo /var/www/kibana/html/restartSuricata.sh',$output,$return_var);
}


if ($_GET['deletels']==1){
  pg_prepare($dbconn, "query", 'DELETE FROM blocks_by_logstashfilter WHERE
    (
      src_ip = $1 AND
      src_port = $2 AND
      dst_ip = $3 AND
      dst_port = $4 AND
      proto = $5 AND
      signature_id = $6
    )
    ');
    $results = pg_execute($dbconn, "query", array($src_id, $src_port, $dest_ip, $dest_port, $proto, $signature_id));
 //TODO make function for reusage
 $file="/var/www/kibana/ebpf/15_kibana_filter.conf";
	//unlink($file);
	$query ="SELECT * FROM blocks_by_logstashfilter";
	$results = pg_query($query);
	$filterrule=" filter { \r\n";

	while ($row = pg_fetch_array($results)){
		$filterrule.=" if {";
	if ($row['src_ip']!='0.0.0.0'){
		$filterrule.=$row['src_ip']." in [client][ip] }";
	}
	if ($row['src_ip']!='0' || $row['src_port']!='0'){
		if ($row['src_ip']!='0.0.0.0'){ $filterrule.=" AND "; }
		$filterrule.=$row['src_port']." in [client][port][number] }";
	}
		if ($row['dst_ip']!='0.0.0.0'){
			if ($row['src_ip']!='0.0.0.0' || $row['src_port']!='0'){ $filterrule.=" AND "; }
		$filterrule.=$row['dst_ip']." in [destination][ip]  }";
	}
		if ($row['dst_port']!='0'){
			if ($row['src_ip']!='0.0.0.0' || $row['src_port']!='0' || $row['dst_ip']!='0.0.0.0'){ $filterrule.=" AND "; }
		$filterrule.=$row['dst_port']." in  [destination][port][number]";
	}
		if ($row['proto']!=''){
			if ($row['src_ip']!='0.0.0.0' || $row['src_port']!='0' || $row['dst_ip']!='0.0.0.0' || $row['dst_port']!='0' ){ $filterrule.=" AND "; }
		$filterrule.=$row['proto']." in [network][transport] ";
	}
		if ($row['signature_id']!=''){
			if ($row['src_ip']!='0.0.0.0' || $row['src_port']!='0' || $row['dst_ip']!='0.0.0.0' || $row['dst_port']!='0' || $row['signature_id']!=''  ){ $filterrule.=" AND "; }
		$filterrule.=$row['signature_id']." in [alert][signature_id]";
	}
  $filterrule.="}\r\n { drop { } }}\r\n";
	}
//	$filterrule.="}"; //Filtered out for 1 Filter rule in logstash

 $ffile = fopen($file,"w");
  fwrite($ffile,$filterrule);
    //file_put_contents($file, $filterrule);
	fclose($ffile);
	}

?>

</head>
<body>
<!-- Äußere Spalten um die beiden Filtertypen zu trennen -->
<div class="two wide column " >

<h3> Kernel Filter </h3>
<div class="ui six column grid">
 <div class="row">
<div class="column"><p> Source IP<p> </div>
<div class="column"><p> Source Port<p> </div>
<div class="column"><p> Destination IP<p> </div>
<div class="column"><p> Destination Port<p> </div>
<div class="column"><p> Protokoll<p> </div>
<div class="column"><p> Anweisung<p> </div>
</div>
</div>
<?php
$query ="SELECT * FROM blocks_by_bpffilter";
        $results = pg_query($query);
        $filterrule="";
		$ctr=0;
		$kf = array(); //=array("ctr" => array("src_port"=>array("dst_ip"=>array("dst_port"=>array("proto")))));
        while ($row = pg_fetch_array($results)){
			$kf[$ctr] = array ();
			$kf[$ctr]['src_ip'] = $row['src_ip'];
			$kf[$ctr]['src_port'] = $row['src_port'];
			$kf[$ctr]['dst_ip'] = $row['dst_ip'];
			$kf[$ctr]['dst_port'] = $row['dst_port'];
			$kf[$ctr]['proto'] = $row['proto'];
		$ctr=$ctr+1;
		}
		$ctr=0;
		//var_dump($kf);
		$kf_ctr=count($kf);
		//echo $kf_ctr;
	 while ($kf_ctr > $ctr){
		echo '

 <form  method="get" class="ui form">
<div class="ui six column grid">
<div class="column"><input type="text" name="src_ip" value="'.$kf[$ctr]["src_ip"].'"></div>
<div class="column"><input type="text" name="src_port" value="'.$kf[$ctr]["src_port"].'"></div>
<div class="column"><input type="text" name="dest_ip" value="'.$kf[$ctr]["dst_ip"].'"></div>
<div class="column"><input type="text" name="dest_port" value="'.$kf[$ctr]["dst_port"].'"></div>
<div class="column"><input type="text" name="proto" value="'.$kf[$ctr]["proto"].'"></div>
<div class="column"><button value="1" name="delete" class="ui negative basic button">Löschen</button></div>
</div>
</form>
</div>';
	$ctr++;
 } ?>
</div>
</div>
<div class="two wide column " >

<h3> Logstash Filter </h3>
<div class="ui seven column grid">
 <div class="row">
<div class="column"><p> Source IP<p> </div>
<div class="column"><p> Source Port<p> </div>
<div class="column"><p> Destination IP<p> </div>
<div class="column"><p> Destination Port<p> </div>
<div class="column"><p> Protokoll<p> </div>
<div class="column"><p> Alarmsignatur<p> </div>
<div class="column"><p> Anweisung<p> </div>
</div>
</div>
<?php
$query ="SELECT * FROM blocks_by_logstashfilter";
        $results = pg_query($query);
        $filterrule="";
		$ctr=0;
		$kf = array(); //=array("ctr" => array("src_port"=>array("dst_ip"=>array("dst_port"=>array("proto")))));
        while ($row = pg_fetch_array($results)){
			$kf[$ctr] = array ();
			$kf[$ctr]['src_ip'] = $row['src_ip'];
			$kf[$ctr]['src_port'] = $row['src_port'];
			$kf[$ctr]['dst_ip'] = $row['dst_ip'];
			$kf[$ctr]['dst_port'] = $row['dst_port'];
			$kf[$ctr]['proto'] = $row['proto'];
			$kf[$ctr]['signature'] = $row['signature'];
			$kf[$ctr]['signature_id'] = $row['signature_id'];
		$ctr=$ctr+1;
		}
		$ctr=0;
		//var_dump($kf);
		$kf_ctr=count($kf);
		//echo $kf_ctr;
	 while ($kf_ctr > $ctr){
		echo '

 <form  method="get" class="ui form">
<div class="ui seven column grid">
<div class="column"><input type="text" name="src_ip" value="'.$kf[$ctr]["src_ip"].'"></div>
<div class="column"><input type="text" name="src_port" value="'.$kf[$ctr]["src_port"].'"></div>
<div class="column"><input type="text" name="dest_ip" value="'.$kf[$ctr]["dst_ip"].'"></div>
<div class="column"><input type="text" name="dest_port" value="'.$kf[$ctr]["dst_port"].'"></div>
<div class="column"><input type="text" name="proto" value="'.$kf[$ctr]["proto"].'"></div>
<div class="column"><input type="text" name="signature" value="'.$kf[$ctr]["signature"].'"></div>
<input type="hidden" name="signature_id" value="'.$kf[$ctr]["signature_id"].'">
<div class="column"><button value="1" name="deletels" class="ui negative basic button">Löschen</button></div>
</div>
</form>
</div>';
	$ctr++;
 } ?>
</div>
</div>
</div>


</div>

<div class="two wide column">
</div>
</body>
</html>
