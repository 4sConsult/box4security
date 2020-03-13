<?php if (!empty($_POST)) {
  $BODY = "Kunde: " . getenv('KUNDE') . "\n". "Kontakt: " . $_POST['email'] . "\n\n" .$_POST['body'];
  $headers   = array();
  $headers[] = "MIME-Version: 1.0";
  $headers[] = "Content-type: text/plain; charset=utf-8";
  $SUBJECT = '['. getenv('KUNDE') .'] ' . (!empty($_POST['subject']) ? $_POST['subject'] : 'BOX4Security FAQ-Kontaktformular');
  $SUBJECT = '=?UTF-8?B?'.base64_encode($SUBJECT).'?=';
  $SENT = mail('0972f9a3.4sconsult.de@emea.teams.ms', $SUBJECT, $BODY, $headers);
} ?>
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
      <div id="faq" class="ui fluid styled accordion">
      <div class="title">
        <i class="dropdown icon"></i>
          Was ist die BOX4Security?
      </div>
      <div class="content text-justify">
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
        <p class="transition hidden">Wünschen Sie Veränderungen des Zeitablaufes oder der Netzkonfiguration, so wenden Sie sich bitte über das <a class="kontakt" href="#kontakt">Kontaktformular</a> an uns.</p>
      </div>
      <div class="title">
        <i class="dropdown icon"></i>
        Wie wird ein aufgetretener Alarm genauer verfolgt?
      </div>
      <div class="content text-justify">
        <p class="transition hidden">Mithilfe von angepinnten Filtern lassen sich aufgetretene Alarme weiter verfolgen. Haben Sie ein auffälliges Datenmerkmal identifiziert, so fahren Sie mit der Maus über die Information und klicken Sie auf die Lupe, die ein Pluszeichen enthält. Sie können nach jeglichen dargestellten Informationen filtern.</p>
        <div class="ui divider"></div>
        <p class="transition hidden">Die folgenden Bilder zeigen Ihnen die Filtermöglichkeiten näher auf.</p>
        <img class="ui fluid bordered image" src="res/faq/filtercategory.jpg">
        <br>
        <img class="ui fluid bordered image" src="res/faq/filtersignature.jpg">
        <br>
        <img class="ui fluid bordered image" src="res/faq/filtersource.jpg">
        <div class="ui divider"></div>
        <p class="transition hidden">Schließlich erscheinen die von Ihnen gewählten Filter unterhalb der Suchleiste am oberen Ende der Seite.</p>
        <img class="ui fluid bordered image" src="res/faq/appliedfilters.jpg">
        <div class="ui divider"></div>
        <p class="transition hidden">Um einen gewählten Filter auf andere Bereiche zu übertragen, klicken Sie mit der linken Maustaste auf den Filter und wählen Sie <i>Pin across all apps</i>. Der gewählte Filter greift nun auch bei Aufruf der übrigen Oberflächen. Angepinnte Filter lassen sich durch Klick auf den Filter und schließlich auf <i>Unpin</i> wieder entfernen.</p>
        <img class="ui fluid bordered image" src="res/faq/pinfilter.jpg">
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
          Eine Übersicht der unterdrückten Alarme sowie die Möglichkeit der Rücknahme dieser, finden Sie unter <i>Adminstration - Filter </i>.
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
        <p class="transition hidden">Um Einfluss auf die Weiterentwicklung der BOX4Security zu nehmen, wenden Sie sich bitte über das <a class="kontakt" href="#kontakt">Kontaktformular</a> an uns.</p>
      </div>
    </div>
    <div class="ui hidden divider"></div>
    <div class="ui message">
      <div class="content">
        <p>
        <i class="svg question circle icon" aria-hidden="true">
        </i>
          Haben Sie eine weitere Frage oder benötigen Sie Unterstützung? <br></p>
          <?php if ($SENT): ?>
            <div class="ui positive message">
              <div class="header">
                Ihre Anfrage wurde versandt.
              </div>
              <p>Vielen Dank für Ihre Anfrage. Wir werden uns zügig bemühen auf Ihr Anliegen zurückzukommen.</p>
            </div>
          <?php endif; ?>
          <div id="contact" class="ui fluid accordion">
            <div class="title">
              <i class="dropdown icon"></i>
              Nehmen Sie hier Kontakt zu uns auf.
            </div>
            <div class="content">
          <form class="ui form" method="post">
            <div class="ui dimmer">
              <div class="ui active loader"></div>
            </div>
            <div class="field">
              <label>Unternehmen</label>
              <input type="text" name="company" value="<?php echo getenv('KUNDE');?>" readonly>
            </div>
            <div class="field">
              <label>Ihre E-Mail-Adresse</label>
              <input type="email" name="email" placeholder="Ihre E-Mailadresse" required>
            </div>
            <div class="field">
              <label>Betreff (optional)</label>
              <input type="text" name="subject" placeholder="BOX4Security: FAQ-Anfrage">
            </div>
            <div class="field">
              <label>Ihr Anliegen</label>
              <textarea name="body"></textarea>
            </div>
            <button id="contactsubmit" class="ui button" type="submit">Abschicken</button>
          </form>
        </div>
        </div>
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
    $('#contact').accordion();
    $('#faq').accordion('open',0);
    $("a.kontakt").click(() => {
      $('#contact').accordion('open', 0);
      setTimeout(() => window.location.href = '#contact', 200);
    })
    $('#contactsubmit').click(() => {
      $('.ui.dimmer').dimmer('show');
    })
    </script>
  </body>
</html>
