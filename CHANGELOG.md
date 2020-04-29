# Changelog
Alle nennenswerten Änderungen dieses Projektes werden in dieser Datei festgehalten.

## [x.x.x](https://gitlab.am-gmbh.de/it-security/b4s/-/tags/x.x.x) - 2020-xx-xx

### Added

### Changed

* Dashboards werden embedded und nicht im Kibana Vollbild angezeigt
* Embedden der Dashboards ermöglicht das setzen von Filtern am Anfang jedes Dashboards

### Fixed

### Deprecated

### Removed

## [1.8.0](https://gitlab.am-gmbh.de/it-security/b4s/-/tags/1.8.0) - 2020-04-29

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


## [1.7.1](https://gitlab.am-gmbh.de/it-security/b4s/-/tags/1.7.1) - 2020-04-15

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

## [1.7.0](https://gitlab.am-gmbh.de/it-security/b4s/-/tags/1.7.0) - 2020-04-01

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

## [1.6.3](https://gitlab.am-gmbh.de/it-security/b4s/-/tags/1.6.3) - 2020-03-18

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
