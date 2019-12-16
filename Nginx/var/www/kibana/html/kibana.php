<html lang="de">
	<head>
		<title>BOX4security</title>
<link rel="stylesheet" type="text/css" href="semantic/dist/semantic.min.css">
<script
  src="https://code.jquery.com/jquery-3.1.1.min.js"
  integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
  crossorigin="anonymous"></script>
<script src="semantic/dist/semantic.min.js"></script>
<?php
      if(isset ($_GET['bpf_filter'])) {
	#$file="/usr/libexec/suricata/ebpf/bypass_filter.bpf";
        $rule="not ("
                                        . (isset($_POST["proto"]) ? $_POST['proto'] . " " : "" )
                                        . (isset($_POST["srcip"]) ? "src host " . $_POST["srcip"] . " " : "" )
                                        . (isset($_POST["srcport"]) ? "src port " . $_POST["srcport"] . " " : "" )
                                        . (isset($_POST["dstip"]) ? "dst host " . $_POST["dstip"] . " " : "" )
                                        . (isset($_POST["dstport"]) ? "dst port " . $_POST["dstport"] . " " : "" )
					. ")\n";
     // <!-- Hier muss eine zweite Abfrage rein. Der Post des Modal Dialoges führt zum schreiben.  -->
    //  file_put_contents($file, $rule, FILE_APPEND);
}
?>
<!-- Dropdown initialisieren -->
<script> $(document).ready(function(){$('.ui.dropdown').dropdown();});</script>
<!-- active class setzen -->
<script>
function setActive(id,pageName,pageLink){
	localStorage.setItem('mainmenustorage',id);
	document.getElementById('secmenu').setAttribute('class','item');
	document.getElementById('vulmenu').setAttribute('class','item');
	document.getElementById('netmenu').setAttribute('class','item');
	document.getElementById('4smenu').setAttribute('class','item right image');
	if (localStorage.getItem('mainmenustorage') == 'secmenu') { document.getElementById('secmenu').setAttribute('class','item active'); }
	if (localStorage.getItem('mainmenustorage') == 'vulmenu') { document.getElementById('vulmenu').setAttribute('class','item active'); }
	if (localStorage.getItem('mainmenustorage') == 'netmenu') { document.getElementById('netmenu').setAttribute('class','item active'); }
	if (localStorage.getItem('mainmenustorage') == '4smenu') { document.getElementById('4smenu').setAttribute('class','item right image active'); }
// Breadcrumb
var siteLink = [];
var siteTitle =[];
//siteLink.push(window.location);
//siteLink.push(document.getElementById('frame').getAttribute('title');
//siteLink.push($('#frame').contents().find("title").text());
localStorage.setItem('link1',localStorage.getItem('link2'));
localStorage.setItem('link2',localStorage.getItem('link3'));
localStorage.setItem('link3',pageName);
localStorage.setItem('linkRef1',localStorage.getItem('linkRef2'));
localStorage.setItem('linkRef2',localStorage.getItem('linkRef3'));
localStorage.setItem('linkRef3',pageLink);
//siteLink[breadcrumbCounter]=(document.getElementById("frame").contentWindow.location.href);
//siteTitle[breadcrumbCounter] =pageName;

if (localStorage.getItem('link1')!='undefined') {	document.getElementsByClassName("breadcrumb")[0].getElementsByTagName('a') [0].innerHTML=localStorage.getItem('link1');}
if (localStorage.getItem('link1')!='undefined') {		document.getElementsByClassName("breadcrumb")[0].getElementsByTagName('a') [0].setAttribute('href',localStorage.getItem('linkRef1'));}
if (localStorage.getItem('link2')!='undefined') {		document.getElementsByClassName("breadcrumb")[0].getElementsByTagName('a') [1].innerHTML=localStorage.getItem('link2');}
if (localStorage.getItem('link2')!='undefined') {		document.getElementsByClassName("breadcrumb")[0].getElementsByTagName('a') [1].setAttribute('href',localStorage.getItem('linkRef2'));}
if (localStorage.getItem('link3')!='undefined') {		document.getElementsByClassName("breadcrumb")[0].getElementsByTagName('a') [2].innerHTML=localStorage.getItem('link3');}
if (localStorage.getItem('link3')!='undefined') {		document.getElementsByClassName("breadcrumb")[0].getElementsByTagName('a') [2].setAttribute('href',localStorage.getItem('linkRef3'));}
}


function printObject(o) {
  var out = '';
  for (var p in o) {
    out += p + ': ' + o[p] + '\n';
  }
  alert(out);
}
</script>


</head>
<?php if(isset ($_GET['bpf_filter'])) {
	echo "<body onload=$('.ui.modal').modal('show')>";
}else { echo "<body onload=setActive()>";
}
?>
<div class="ui tabular menu">
<div class="active item" id="secmenu">
<!-- Menüpunkte mit Untermenü sind divs -->
<div class="ui dropdown pointing link item">
      <i class="globe icon" id="securitymenu"></i> SIEM
	  <i class="dropdown icon"></i>
      <div class="menu">
        <a class="item"  href="/kibana/app/kibana#/dashboard/a7bfd050-ce1d-11e9-943f-fdbfa2556276" onclick="setActive('secmenu','Intrusion Detection','/kibana/app/kibana#/dashboard/a7bfd050-ce1d-11e9-943f-fdbfa2556276')"
		target="frame" >Intrusion Detection</a>
<!--	<a class="item" href="https://192.168.90.236/kibana/app/kibana#/dashboard/2be46cb0-27f2-11e9-89af-fd12d59dac90-ecs?_g=(filters%3A!())" target="frame"> Systemaudit </a> -->
     </div></div></div>
<!-- Menüpunkte ohne Untermenü sind a -->
<div class="active item" id="vulmenu">
	<div class="ui dropdown pointing link item">
	<i class="bug icon"></i> Schwachstellen</a>
	<i class="dropdown icon"></i>
     <div class="menu">
	<a class="item" id="vulmenu" href="/kibana/app/kibana#/dashboard/f8712020-cefa-11e9-943f-fdbfa2556276" target="frame"  onclick="setActive('vulmenu','Schwachstellenübersicht','/kibana/app/kibana#/dashboard/f8712020-cefa-11e9-943f-fdbfa2556276')"> Schwachstellenübersicht </a>
	<a class="item" id="vulmenu" href="/kibana/app/kibana#/dashboard/bcb41f20-f18b-11e9-a167-6152d43fae94" target="frame"  onclick="setActive('vulmenu','Schwachstellendetails','/kibana/app/kibana#/dashboard/bcb41f20-f18b-11e9-a167-6152d43fae94')"> Schwachstellendetails </a>
	<a class="item" id="vulmenu" href="/kibana/app/kibana#/dashboard/87c24930-ceff-11e9-943f-fdbfa2556276" target="frame"  onclick="setActive('vulmenu','Schwachstellenverlauf','/kibana/app/kibana#/dashboard/87c24930-ceff-11e9-943f-fdbfa2556276')"> Schwachstellenverlauf </a>
	     </div></div></div>



	<div class="item" id="netmenu">
	<div class="ui dropdown pointing link item">
     <i class="sitemap icon"></i> Netzwerk <i class="dropdown icon"></i>
      <div class="menu">
	<a class="item" href="/kibana/app/kibana#/dashboard/e5fbd440-ce2c-11e9-943f-fdbfa2556276"  onclick="setActive('netmenu','Datenflüsse','/kibana/app/kibana#/dashboard/e5fbd440-ce2c-11e9-943f-fdbfa2556276')" target="frame">Datenflüsse</a>
	<a class="item" href="/kibana/app/kibana#/dashboard/c2b4c450-ce46-11e9-943f-fdbfa2556276" onclick="setActive('netmenu','GeoIP & ASN','/kibana/app/kibana#/dashboard/c2b4c450-ce46-11e9-943f-fdbfa2556276')" target="frame">GeoIP & ASN</a>
 	<a class="item" href="/kibana/app/kibana#/dashboard/Winlogbeat-Dashboard-ecs" onclick="setActive('netmenu','Windows Logs','/kibana/app/kibana#/dashboard/Winlogbeat-Dashboard-ecs')" target ="frame">Windows Logs</a>
	<a class="item" href="/kibana/app/kibana#/dashboard/Metricbeat-system-overview-ecs" onclick="setActive('netmenu','Systemmetriken Übersicht','/kibana/app/kibana#/dashboard/Metricbeat-system-overview-ecs')" target="frame">Systemmetriken Übersicht</a>
	<a class="item" href="/kibana/app/kibana#/dashboard/79ffd6e0-faa0-11e6-947f-177f697178b8-ecs" onclick="setActive('netmenu','Systemmetriken Details','/kibana/app/kibana#/dashboard/79ffd6e0-faa0-11e6-947f-177f697178b8-ecs')" target="frame"> Systemmetriken Details</a>
	<a class="item" href="/kibana/app/kibana#/dashboard/2bb743a0-cfe2-11e9-99db-bb656e2bf55c" onclick="setActive('netmenu','Verbindungsüberwachung','/kibana/app/kibana#/dashboard/2bb743a0-cfe2-11e9-99db-bb656e2bf55c')" target="frame">Verbindungsüberwachung</a>
	<a class="item" href="/kibana/app/kibana#/dashboard/6ffffcd0-cfad-11e9-943f-fdbfa2556276" onclick="setActive('netmenu','Statistiken','/kibana/app/kibana#/dashboard/6ffffcd0-cfad-11e9-943f-fdbfa2556276')" target="frame">Statistiken</a>
	</div></div></div>

<!-- <div class="menu">
<div class="item ui large breadcrumb">

<a class=" section"id="bc1" target="frame"> </a>
  <i class="right chevron icon divider"></i>
  <a class=" section" id="bc2" target="frame"></a>
  <i class=" right chevron icon divider"></i>
  <a class=" section active" id="bc3" target="frame"></a>
</div></div> -->




	<a class="item right image" id="4smenu" href="https://www.4sconsult.de/" onclick="setActive('4smenu')" target="frame"><img class="ui small image" src="/res/Box4S_Logo.png"></a>
</div>
</div>
<div height="100%">
<iframe  width="100%" height="92%" frameborder="0" id="frame" src="/kibana/app/kibana#/dashboard/a7bfd050-ce1d-11e9-943f-fdbfa2556276?_g=()" name="frame">
</div>
</iframe>

<form method="post" class="ui modal form">

<!-- Lade bestehende Blocks -->

<div class="ui six column doubling stackable grid container with=300px">
<div class="ui grid">
	<div class="row">
  <div class="three wide column">
    <p>Source IP</p>
    <div class="ui input">
		<input type="text" name="srcip" value="<?php echo $src_ip; ?>">
	</div>
  </div>
  <div class="three wide column">
    <p>Source Port</p>
    <div class="ui input">
		<input type="text" name="srcport" value="<?php echo $src_port; ?>">
	</div>
  </div>
  <div class="three wide column">
    <p>Destination IP</p>
    <div class="ui input">
		<input type="text" name="dstip" value="<?php echo $dest_ip; ?>">
	</div>
  </div>
  <div class="three wide column">
    <p>Destination Port</p>
    <div class="ui input">
		<input type="text" name="dstport" value="<?php echo $dest_port; ?>">
	</div>
  </div>
  <div class="three wide column">
    <p>Protocol</p>
	<select name="proto" class="ui dropdown">
		<option value=""></option>
  	<option value="tcp">tcp</option>
  	<option value="udp">udp</option>
		<option value="icmp">icmp</option>
	</select>
	</div>
	</div>
	<div class="row" style="margin-bottom: 20px">
		<div class="three wide column">
			<button class="ui button" type="submit">Submit</button>
		</div>
	</div>
</div>
</form>
<footer>
</footer>
</html>
