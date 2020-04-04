# Changelog
Alle nennenswerten Änderungen dieses Projektes werden in dieser Datei festgehalten.

## [1.x](x) - 2020-xx-xx

### Compatible with
* Elastic Products 7.6.2
* OpenVAS 9.0.3
* Suricata 5.0.1

### Added
* Automatischer Healthcheck für Weboberfläche hinzugefügt
* Darstellung des Changelogs in Updatesektion der Weboberfläche

### Changed
* Version von PostgreSQL festgelegt
* Version von Nginx festgelegt
* Dockerimage für Logstash in Betrieb genommen
* Elasticsearch auf 7.6.2 aktualisiert
* Kibana auf 7.6.2 aktualisiert

### Fixed
*

### Deprecated
*

### Removed
*

## [1.7.0](https://gitlab.am-gmbh.de/it-security/b4s/-/tags/1.7) - 2020-04-01

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
