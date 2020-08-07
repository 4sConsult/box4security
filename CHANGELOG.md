# Changelog
Alle nennenswerten Änderungen dieses Projektes werden in dieser Datei festgehalten.

## [x.x.x](https://gitlab.com/4sconsult/box4s/-/tags/x.x.x) - 2020-xx-xx

### Added
* Modulare Konfiguration der BOX4security eingefügt.

### Changed
* Änderungen an der Einstufung und Bewertung von Schwachstellen vorgenommen
* Wazuh nun als freischaltbares Modul außerhalb des Standards implementiert.
* Änderungen am rollenbasierten Routing der WebApp vorgenommen. Vorherige Lesezeichen könnten jetzt nicht mehr funktionieren.
* Alle API-Endpunkte auf gemeinsamen Präfix `/api` verschoben.

### Optimized
* Das Betriebssystem der BOX4security wird sich nun regelmäßig automatisch aktualisieren
* Darstellung eines Hinweises, sollte das Anlegen eines Nutzers aufgrund fehlerhafter SMTP-Konfiguration fehlschlagen.
* Konfiguration der WebApp-URLs, die den Rollen zugeordnet sind, verbessert.
* IDS-Alarme werden nun zeitlich exakt indiziert.

### Fixed
* Internen Berechtigungsfehler behoben
* Fehler behoben, bei dem Nutzer trotz Config-Rolle nicht die Konfiguration einsehen durften.
* Bug behoben, bei dem das IDS die Filterregeln (BPF) nicht direkt übernahm.
* BSI-Alarme des IDS werden wieder angewandt und nicht länger zu hoch evaluiert.
* Leere Felder bei der Filtererstellung werden nun korrekt als Wildcard (`*`) interpretiert.

### Deprecated
* Ursprüngliche Endpunkte die das Update betreffen erhalten. Diese werden jedoch mit dem folgenden Release entfernt.

### Removed


## [1.8.5](https://gitlab.com/4sconsult/box4s/-/tags/1.8.5) - 2020-07-22

### Added
* Neue Rolle *Config* zur Verwaltung der Konfiguration hinzugefügt
* Oberfläche zur Konfiguration der BOX4s hinzugefügt
* Neustart der BOX4s-Einrichtung nun erlaubt, solange nur ein, nicht per E-Mail bestätigter Nutzer existiert
* Rate Limiting zur Abwehr von Brute-Forcing beim Einloggen eingeführt

### Changed
* Gesperrte Nutzer werden nun sofort ausgeloggt
* SSH via Passwort zur BOX4s nicht länger erlaubt - stattdessen wird nur noch SSH mit Public-Key-Authentifikation durch 4sConsult-Mitarbeiter zugelassen
* Hostsystem auf Ubuntu 20.04 LTS aktualisiert
* HTTPS-Zertifikat erneuert

### Optimized
* Geheimnisse werden erst bei Installation entschlüsselt und liegen zuvor nur verschlüsselt vor
* API-Endpunkte des Update-Prozesses weiter gegen unauthorisierten Zugriff gehärtet
* Ein bei der initialen Registrierung nicht erreichbarer SMTP-Server führt nicht mehr dazu, dass die Registrierung fehlschlägt

### Fixed
* Fehler behoben, bei dem bei nicht zuzuordnenden öffentlichen IP-Adressbereichen ein Templatestring nicht ausgefüllt wurde
* Bug behoben, der dazu führte, dass Events aus Suricata nicht gespeichert wurden

### Deprecated

### Removed
* Geheimnisse aus Source Code entfernt

## [1.8.4](https://gitlab.com/4sconsult/box4s/-/tags/1.8.4) - 2020-06-23

### Added
* Alarmierung mittels aktivierbarer, ausgewählter BOX4s Quick Alerts hinzugefügt
* Rolle *Alerts* zur Kontrolle von Alarmierungen hinzugefügt
* Die Box kann nun über `curl -sL https://gitlab.com/snippets/1982942/raw | sudo bash` installiert werden
* Wazuh Clients können direkt von der BOX4security heruntergeladen werden (Für Endgeräte ohne direkte Internetverbindung)
* Wiki um einen Eintrag zum Thema Wazuh erweitert

### Changed
* Die BOX4security benötigt nun keine VPN-Verbindung mehr, um Softwareaktualisierungen zu beziehen
* Fehlermeldung eingeführt, wenn ein User-Manager einen SuperAdmin versucht zu löschen
* Fehlermeldung angepasst, wenn jemand nicht autorisiert oder nicht authentifiziert ist
* Benutzer werden nach dem Login immer auf eine Seite weitergeleitet, für die sie auch freigeschaltet sind
* Benutzer können nun nur noch die Bereiche im Menü sehen, für die sie auch die notwendigen Rechte haben
* Standardnachricht von Elasticsearch bei der ersten Inbetriebnahme ausgeblendet

### Optimized
* Bei jedem Update werden die alten Dockerimages gelöscht, um Speicherplatz zu sparen
* Dockerimages aktualisiert und optimiert

### Fixed
* Fehlerhafte Datenauswahl im Schwachstellenverlauf für kritisches und hohes Risiko behoben
* Fehlschlagendes Einspeisen von Schwachstellenreports bei fehlerhaftem Zeitstempel behoben

### Deprecated

### Removed

## [1.8.2](https://gitlab.com/4sconsult/box4s/-/tags/1.8.2) - 2020-05-27

### Added
- Plattform zur Dokumentation eingefügt.
- Neue Rolle zur Freigabe der Dokumentation eingefügt.
- Neben offizieller, geschützer Dokumentation wurde die Möglichkeit eingefügt, eigene Seiten der Doku zu erstellen.

### Changed
- Dashboard des Schwachstellen-Verlaufs zeigt nun den Verlauf der letzten 90 Tage.
- Zahlen der einzelnen Schwachstellenkategorie des Schwachstellen-Verlauf-Dashboards basieren nun auf den letzten 7 Tagen.

### Fixed

* Fehler in der automatischen Überwachung wiederkehrender Aufgaben behoben.
* Fehler bei der Berechnung der Scores (IT-Security, Alarm, Schwachstellen) behoben.
* Fehler behoben, bei dem das wöchentliche Update der Ressourcen zum Fehlschlagen von GeoIP-Auflösungen führte.
* Fehler behoben, bei dem die Schwachstellenauswertung nicht in die Visualiserung übertragen wurde.

### Deprecated

### Removed
* Auditbeat als ehemalige Endgerätelösung zugunsten Wazuhs abgelöst.
* Datenverarbeitung von ehemaligen Endgerätelösungen Auditbeat und Winlogbeat entfernt.

## [1.8.1](https://gitlab.com/4sconsult/box4s/-/tags/1.8.1) - 2020-05-13

### Added
- Login-Auth-Provider durch WebApp-Login für weitere Anbindungen bereitgestellt.
- Setzen von Filtern am Anfang jedes Dashboards ermöglicht.

### Changed
- Direkten Zugriff auf die Visualisierungssoftware verwehrt.
- Einbetten der Visualisierungssoftware nur noch gegen Authentisierung an Login-Auth-Provider genehmigt.
- Dashboards werden embedded und nicht mehr im Vollbildmodus der Visualisierungssoftware angezeigt.

### Fixed
*  Bug behoben, bei dem es Super-Admins nicht erlaubt war Teile der API zu nutzen. \
  **WICHIG**: Ein Update von 1.8.0 auf diese Version muss von einem Nutzer mit *Updates*-Rolle angestoßen werden, damit der Auftrag entgegengenommen wird. Der Super-Admin muss also temporär zusätzlich die *Updates*-Rolle erhalten, um das System aktualisieren zu dürfen.
* Fehler behoben, bei dem der administrative Nutzer beim Anlegen eines weiteren Benutzers immer dessen Einladung erhielt, auch wenn dies nicht angefordert war.
* Bei fehlerhaften Updates wird nach dem Rollback nun der fehlererzeugende Update-Tag lokal gelöscht, um Hotfixes zu ermöglichen.
* Schwachstellen werden jetzt wie angedacht bis zu 180 Tage auf der Box gespeichert und nicht länger nach 30 Tagen gelöscht, um Langzeitdatenauswertung zu ermöglichen.

### Deprecated

### Removed


## [1.8.0](https://gitlab.com/4sconsult/box4s/-/tags/1.8.0) - 2020-04-29

### Added
* Aufforderung zum Erstellen eines Administrationsusers nach Update auf diese oder Installation dieser Version eingeführt
* Benutzerauthentifizierung eingeführt
* Weboberfläche der BOX4s nur noch nach Benutzerauthentifizierung sichtbar
* Benutzerauthentifizierung für sensible API-Punkte erforderlich
* E-Mail-Benachrichtigung bei Ereignissen der Benutzerauthentifizierung eingeführt
* Benutzerverwaltung zum Anlegen, Bearbeiten und Löschen von Benutzern eingeführt
* Rollenkonzept eingeführt
* Endgerätemonitoring durch Wazuh in Webapp eingepflegt

### Changed
* Neues Box4Security Logo in Website integriert
* Nachricht bei nicht erfolgreicher Verbindung mit Update Server angepasst
* Dockerimage für OpenVAS in Betrieb genommen

### Fixed
* Problem behoben, das bei dem Einpflegen von Filtern Suricata nicht neustarten ließ
* Problem behoben, das die Scores falsch berechnete

### Deprecated
* Ursprüngliches Initialisierungsskript für automatische Einrichtung wird in zwei Releases nicht mehr unterstützt
* Winlogbeat wird zukünftig durch Wazuh ersetzt und wird in einem Release nicht mehr verfügbar sein
* Auditbeat wird zukünftig durch Wazuh ersetzt und wird in einem Release nicht mehr verfügbar sein

### Removed


## [1.7.1](https://gitlab.com/4sconsult/box4s/-/tags/1.7.1) - 2020-04-15

### Added
* Überwachung des Update-Prozesses mit automatischem Rollback auf gesicherten Zustand bei Misserfolg
* Wazuh-Manager als Dockercontainer bereitgestellt
* Automatischer Healthcheck für Weboberfläche hinzugefügt
* Darstellung des Changelogs in Updatesektion der Weboberfläche
* Anzeige des Links zum zukünftigen Unterdrücken eines Alarms auf dem "[SIEM] - Alarme" Dashboard
* Link zum Unterdrücken von Alarmen im Dashboard "[SIEM] - Alarme" verfügbar
* Ladestatus & Fehleranzeige bei Verbindung zu Versionskontrollserver

### Changed
* Installationszeit der Box um 75% verkürzt
* Dockerimage für Logstash in Betrieb genommen
* Dockerimage für Auditbeat in Betrieb genommen
* Dockerimage für Filebeat in Betrieb genommen
* Dockerimage für Metricbeat in Betrieb genommen
* Dockerimage für Suricata in Betrieb genommen
* Dockerimage für DNSmasq in Betrieb genommen
* Dockerimage für Heartbeat in Betrieb genommen
* Update nur noch auf freigegebene Releases möglich
* Maximaler Arbeitsspeicher des Systems wird berechnet und aufgeteilt
* Projektstruktur grundlegend zugunsten verbesserter Übersichtlichkeit und Dateigröße geändert
* Betrachtungszeitraum der Dashboards festgelegt

### Fixed
* Kleine Fehler nicht-aufgelöster Referenzen in Dashboards beseitigt

### Deprecated
* Winlogbeat wird zukünftig durch Wazuh ersetzt und wird in zwei Releases nicht mehr verfügbar sein
* Auditbeat wird zukünftig durch Wazuh ersetzt und wird in zwei Releases nicht mehr verfügbar sein

### Removed
* Veraltete, sperrige Dateien entfernt um Speicherplatz und Netzwerkvolumen zu senken

## [1.7.0](https://gitlab.com/4sconsult/box4s/-/tags/1.7.0) - 2020-04-01

### Compatible with
* Elastic Products 7.5.0
* OpenVAS 9.0.3
* Suricata 5.0.1

### Added
* Automatischer VPN-Verbindungsaufbau
* Dashboard "Übersicht" für den Bereich SIEM hinzugefügt
* Dashboard "Alarme" für den Bereich SIEM hinzugefügt
* Dashboard "ASN" für den Bereich SIEM hinzugefügt
* Dashboard "HTTP" für den Bereich SIEM hinzugefügt
* Dashboard "DNS" für den Bereich SIEM hinzugefügt
* Dashboard "Protokolle & Dienste" für den Bereich SIEM hinzugefügt
* Dashboard "Social Media (Alpha)" für den Bereich SIEM hinzugefügt - die Visualisierungen benötigen Feedback und sind daher noch im Alpha-Status
* Die Startseite ist nun als Startseite in Share verfügbar
* Die Dashboards des Bereichs "SIEM" sind nun in Share verfügbar
* Die Dashboards des Bereichs "Netzwerk" sind nun in Share verfügbar
* Die Dashboards des Bereichs "Schwachstellen" sind nun in Share verfügbar
* Dashboard "Übersicht" für den Bereich Schwachstellen hinzugefügt
* Dashboard "Verlauf" für den Bereich Schwachstellen hinzugefügt
* Dashboard "Schwachstellendetails" für den Bereich "Schwachstellen" hinzugefügt
* API als Schnittstelle zwischen WebApp und übrigen Teilen der BOX4s implementiert
* Anlegen von Filtern auf Filterübersicht
* Löschen einzelner oder aller Filter
* E-Mail-Überwachung von Routineaufgaben
* Download des Updatelogs möglich

### Changed
* Neuentwicklung WebApp für mehr Stabilität und Funktionalität
* Dockerimage für Elasticsearch in Betrieb genommen
* Dockerimage für Kibana in Betrieb genommen
* Dockerimage für Nginx in Betrieb genommen
* Dockerimage für PostgreSQL in Betrieb genommen
* Menüpunkt "Schwachstellen" neu strukturiert
* Menüpunkt "SIEM" neu strukturiert
* Das Dashboard der Startseite zeigt standardmäßig immer Daten von heute
* Die Dashboards im Bereich "SIEM" zeigen standardmäßig immer Daten von heute
* Die Dashboards im Bereich "Schwachstellen" zeigen standardmäßig immer Daten von den letzten 30 Tagen
* Die Dashboards im Bereich "Netzwerk" zeigen standardmäßig immer Daten von den letzten 30 Tagen
* Diverse Optimierungen in Funktionalität und Stabilität
* Update-Übersicht zeigt nun auch Kurzbeschreibung und Release-Zeitpunkt der Updates
* Styling der Update-Seite erneuert
* Styling der Filter-Seite erneuert
* Umbenennung des Menüpunktes `Administration` -> `Update`

### Fixed
* Fehlerhafte Installation des Score-Indizes behoben
* Einige Dashboards haben sich nicht über den gesamten Bildschirm erstreckt, sodass es zu unschönen Anzeigen in Share kam

### Deprecated
* Vorherige link_surpress_bpf-Links können nicht mehr eingesetzt werden, um vereinfacht Filter zu setzen

### Removed
* Elasticsearch-Installation auf Host entfernt
* Kibana-Installation auf Host entfernt
* Dashboard "Intrusion Detection" in dem Bereich SIEM entfernt
* Dashboard "Schwachstellenübersicht" in dem Bereich Schwachstellen entfernt

## [1.6.3](https://gitlab.com/4sconsult/box4s/-/tags/1.6.3) - 2020-03-18

### Compatible with
* Elastic Products 7.5.0

### Added
* Master-Branch aus ursprünglichem GitLab in Version 1.6.2 übernommen
* Update-Funktion zur Aktualisierung der BOX4security nach Tags aus dem GitLab
* Dashboard "Übersicht" zum Netzwerkmenü hinzugefügt

### Changed
* Installscript auf neues GitLab migriert
* Neue Startseite eingefügt
* Menüpunkt "Netzwerk" neu strukturiert
* Dashboards sind im Bereich "Netzwerk" nun standardmäßig immer im Vollbild
* E-Mailzugang erneruert

### Fixed
* Bug behoben, der bei Installation falsche BPF schrieb und somit den Start von Suricata verhinderte.
* Stored-XSS-Lücke bei Ausgabe von Filtern entfernt.
* SQL-Injection Lücke beim Anlegen von Filtern entfernt.
* Bug behoben, der den Index für die Scores falsch anlegte
* Bug behoben, der den IT-Security Score falsch berechnete

### Deprecated

### Removed
* Dashboard "Statistiken" aus dem Netzwerkmenü entfernt
* Dashboard "Verbindungsüberwachung" aus dem Netzwerkmenü entfernt
* Dashboard "Windows Logs" aus dem Netzwerkmenü entfernt
* Dashboard "Systemmetriken Übersicht" aus dem Netzwerkmenü entfernt
* Dashboard "Systemmetriken Details" aus dem Netzwerkmenü entfernt
