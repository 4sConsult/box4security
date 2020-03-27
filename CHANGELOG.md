# Changelog
Alle nennenswerten Änderungen dieses Projektes werden in dieser Datei festgehalten.

## [1.6.4](x) - 2020-x-x

### Compatible with
* Elastic Products 7.3.0

### Added
* Automatischer VPN-Verbindungsaufbau
* Dashboard "Übersicht" für den Bereich SIEM hinzugefügt
* Dashboard "Alarme" für den Bereich SIEM hinzugefügt
* Dashboard "ASN" für den Bereich SIEM hinzugefügt
* Dashboard "HTTP" für den Bereich SIEM hinzugefügt
* Dashboard "DNS" für den Bereich SIEM hinzugefügt
* Dashboard "Protokolle & Dienste" für den Bereich SIEM hinzugefügt
* Die Startseite ist nun als Startseite in Share verfügbar
* Die Dashboards des Bereichs "SIEM" sind nun in Share verfügbar
* Die Dashboards des Bereichs "Netzwerk" sind nun in Share verfügbar
* Die Dashboards des Bereichs "Schwachstellen" sind nun in Share verfügbar
* Dashboard "Übersicht" für den Bereich "Schwachstellen hinzugefügt"
* Dashboard "Schwachstellendetails" für den Bereich "Schwachstellen" hinzugefügt

### Changed
* Dockerimage für Elasticsearch in Betrieb genommen
* Dockerimage für Kibana in Betrieb genommen

### Fixed
* Fehlerhafte Installation des Score-Indizes behoben

### Deprecated

### Removed
* Elasticsearch-Installation auf Host entfernt
* Kibana-Installation auf Host entfernt
* Dashboard "Intrusion Detection" in dem Bereich SIEM entfernt
* Dashbaord "Schwachstellenübersicht" in dem Bereich Schwachstellen entfernt

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
