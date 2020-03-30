# Changelog
Alle nennenswerten Änderungen dieses Projektes werden in dieser Datei festgehalten.

## [1.6.4.](x) - 2020-x-x

### Compatible with
* Elastic Products 7.5.0

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
* WebApp als Dockeranwendung in Betrieb genommen
* API als Schnittstelle zwischen WebApp und übrigen Teilen der BOX4s implementiert
* Anlegen von Filtern auf Filterübersicht
* Löschen einzelner oder aller Filter

### Changed
* Web-Anwendung effizienter und übersichtlicher reentwickelt
* Kibana-BasePath auf `/kibana` angepasst
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
* Der Log des Updatescripts ist nun unter /var/log/box4s/update.log einsehbar
* Update-Übersicht zeigt nun auch Kurzbeschreibung und Release-Zeitpunkt der Updates
* Styling der Update-Seite erneuert
* Styling der Filter-Seite erneuert

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

## [1.6.3](x) - 2020-03-18

### Compatible with
* Elastic Products 7.3.0

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
