Outdated Doku 
========

# fetch_qc.py

### Zweck
Auslesen der vom Kunden hinterlegten Systeminformationen aus der Plattform API und Einbinden der Netz- und Systeminformationen zum Anreichern der Daten in Logstash.

### Bedienung
**Start**: ```sudo python3 fetch_qc.py```

**Hilfe ausgeben und verlassen**: ```sudo python3 fetch_qc.py -h```

Rootrechte sind erforderlich zum Bearbeiten von Systemdateien.

Das Skript arbeitet mit einer Konfiguration von 4 Variablen:
1. **Host**: Standard ist it-security.am-gmbh.de, wird als API Endpunkt genutzt. (/api/ wird angehängt). mit **-h localhost** kann das Script mit lokalem Webserver getestet werden.
2. **User**: Benutzer um sich bei der Plattform anzumelden. Muss mit dem API-Key übereinstimmen. Mit **-u ct**//**--user ct** kann ein Nutzer spezifiziert werden. Wenn nicht definiert, wird das Skript zu Laufzeit nach einem Benutzernamen fragen
3. **API-Token**: Um sich gegenber der Plattform zu authentifizieren ist ein API-Token erforderlich. Diesen erhält man als eingeloggter AM-Mitarbeiter auf der Plattform unter Einstellungen. Ein Token ist 24 Stunden gültig. Mit **-p 3624gGGH3743GV/--pass 3624gGGH3743GV** kann ein Token vorgegeben werden. Wird der Token nicht angegeben, fragt das Skript zur Laufzeit danach. **WICHTIG: NICHT DAS PLATTFORM-KENNWORT VERWENDEN!!!**
4. **Quickcheck-ID**: Gibt den Quickcheck vor, von dem die Informationen über die API ausgelesen werden sollen. z.B. **-q 14/--quickcheck 14**. Das Skript fragt bei Laufzeit danach, wenn nicht vorher angegeben.


Besondere Option ist ```-i```. Damit wird die Zertifikatsvalidation abgeschaltet.

### Vorraussetzungen
1. API-Token s.o.
2. Die Configdateien von Logstash müssen entsprechend des Git-Repos mit Platzhaltern gefüllt sein. Zurückgesetzt werden.
3. Python3.5

### Effekt
Das Skript erfüllt mehrere Funktionen:

1. Es werden die Netzwerk/System-Dateien über den Quickcheck via ID aus der API gelesen.
2. Es werden die Daten in zwei CSV-Dateien exportiert: ```/home/amadmin/{QUICKCHECKID}_systems.csv``` und ```/home/amadmin/{QUICKCHECKID}_networks.csv```.
3. Es werden die Platzhalter in ```/etc/logstash``` sowie das nmap-Script ```/home/amadmin/scan.sh``` gefüllt.

