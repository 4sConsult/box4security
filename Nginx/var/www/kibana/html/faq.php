<!DOCTYPE html>
<html lang="de" dir="ltr">
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" type="text/css" href="semantic/dist/semantic.min.css">
    <link rel="stylesheet" type="text/css" href="res/box4s.css">
    <title>BOX4security FAQ</title>
  </head>
  <body>
    <div class="ui main text container">
      <h1 class="ui header">BOX4Security - FAQ</h1>
      <div class="ui inverted section divider"></div>
      <div class="ui fluid styled accordion">
      <div class="title">
        <i class="dropdown icon"></i>
          Was ist die BOX4Security?
      </div>
      <div class="content text-justify">
        <!-- <img class="ui small image" src="res/Box4S_Logo.png"> -->
        <span class="transition hidden">Die BOX4Security ist eine von 4sConsult entwickelte Security-Lösung für das Firmennetz. Durch Aufzeichnung und Analyse von Netzwerkverehrsinformationen, Systemscans nach Schwachstellen und grafische Darstellung der Alarme und Warnungen in Dashboards kann jederzeit der Sicherheitszustand des Firmennetzes überwacht werden.</span>
      </div>
      <div class="title">
        <i class="dropdown icon"></i>
          Welche Übersichten gibt es?
      </div>
      <div class="content text-justify">
        <img class="ui centered fluid image" src="res/nav.png">
        <p class="transition hidden">Die Oberfläche der BOX4Security verfügt über 4 übergeordnete Bereiche.</p>
        <p class="transition hidden"><b>SIEM</b> - Dieser Bereich enthält Dashboards zur Auswertung des LIVE-Angriffserkennungssystem. Die Informationen basieren auf Auswertungen des Netzwerkverkehrs.</p>
        <p class="transition hidden"><b>Schwachstellen</b> - Dieser Bereich stellt die ermittelten Schwachstellen der Firmensysteme übersichtlich, im Detail sowie im zeitlichen Verlauf dar.</p>
        <p class="transition hidden"><b>Netzwerk</b> - Dieser Bereich enthält Dashboards zur Darstellung des Datenflusses, sowie Geo-Location- und Netzbetreiber-Auswertungen der am Verkehr beteiligten IP-Adressen. Ebenso werden hier systemeigene Log- und Vitalwerte dargestellt.</p>
        <p class="transition hidden"><b>Administration</b> - Im administrativen Bereich können verfügbare Updates angewandt werden. Ebenso findet sich hier eine Übersicht der vorgenommenen Filter (siehe auch <i>"Wie können False Positives ausgeblendet werden?"</i>).</p>
      </div>
      <div class="title">
        <i class="dropdown icon"></i>
        Wie wird der Schwachstellenscanner konfiguriert?
      </div>
      <div class="content text-justify">
        <p class="transition hidden">Der Schwachstellenscanner wurde bei der Installation der BOX4Security eingerichtet. Der wöchentliche Ablauf der Schwachstellenscans sowie die betrachteten Netzwerke wurden nach gemeinsamer Vereinbarung zwischen der IT-Administration Ihres Unternehmens und den Mitarbeitern der 4sConsult GmbH implementiert.</p>
        <p class="transition hidden">Wünschen Sie Veränderungen des Zeitablaufes oder der Netzkonfiguration, so wenden Sie sich bitte über das <a href="#kontakt">Kontaktformular</a> an uns.</p>
      </div>
      <div class="title">
        <i class="dropdown icon"></i>
          Wie können False Positives ausgeblendet werden?
      </div>
      <div class="content text-justify">
        <p class="transition hidden">Haben Sie einen False Positive identifiziert, so lässt sich dieser Alarm künftig von der Aufzeichnung ausnehmen. Gehen Sie dazu wie folgt vor:</p>
        <p class="transition hidden">
          <div class="ui ordered list">
            <span class="item">False Positive identifizieren</span>
            <span class="item">Schaltfläche "Alarm unterdrücken" wählen</span>
            <span class="item">Indikatoren im Dialog überprüfen, ggfs. ergänzen oder verringern</span>
            <span class="item">Dialog absenden</span>
          </div>
          Nachdem diese Prozedur ausgeführt wurde, wird der Alarm künftig nicht mehr aufgezeichnet und erscheint in Zukunft nicht mehr im Dashboards.
          Eine Übersicht der unterdrückten Alarme sowie die Möglichkeit der Rücknahme dieser, finden Sie unter <i>Adminstration - Filter </i>
        </p>
        <p class="transition hidden">Gerne folgen Sie auch diesem Video zur Durchführung der obigen Prozedur:</p>
        <div class="transition hidden fluid">
          <video class="transition" controls src="res/SuppressAlarms.mp4">
          </video>
        </div>
      </div>
      <div class="title">
        <i class="dropdown icon"></i>
          Alarme unterdrücken: Worin unterscheiden sich die Methoden Kernel und Logstash?
      </div>
      <div class="content text-justify">
        <p class="transition hidden"><b>Kernel</b> - Über die Option des Kernels lassen sich Pakete bereits vor der Aufzeichnung durch das Intrusion Detection System ausschließen. Diese Option ist die performanteste. Es kann allerdings nur nach Informationen der Netz- und Transportschicht, d.h. IP-Adressen, Port und Protokoll, gefiltert werden.</p>
        <p class="transition hidden"><b>Logstash</b> - Die Filterfunktion Logstash greift nach Aufzeichnug des Paketes durch das Intrusion Detection System. Hier lassen sich zusätzlich gezielt Alarme anhand ihrer Signatur verwerfen.</p>
      </div>
      <div class="title">
        <i class="dropdown icon"></i>
          Wie können fehlende Features angefragt werden?
      </div>
      <div class="content text-justify">
        <p class="transition hidden">Um Einfluss auf die Weiterentwicklung der BOX4Security zu nehmen, wenden Sie sich bitte über das <a href="#kontakt">Kontaktformular</a> an uns.</p>
      </div>
    </div>
    <div class="ui hidden divider"></div>
    <div class="ui message">
      <div class="content">
        <p>
        <i class="svg question circle icon" aria-hidden="true">
        </i>
          Haben Sie eine weitere Frage? <br> Kontaktieren Sie unsere Mitarbeiter per E-Mail an <a href="mailto:box@4sconsult.de">box@4sconsult.de</a>.</p>
        </div>
      </div>
    </div>
    <div class="ui vertical footer segment">
      <div class="ui center aligned container">
      <img src="/res/Box4S_Logo.png" class="ui centered small image">
    </div>
    </div>
    <script
      src="https://code.jquery.com/jquery-3.1.1.min.js"
      integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
      crossorigin="anonymous"></script>
    <script src="semantic/dist/semantic.min.js"></script>
    <script type="text/javascript">
    $('.ui.accordion').accordion('open',0);
    </script>
  </body>
</html>
