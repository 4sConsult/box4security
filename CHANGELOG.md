# Changelog
Alle nennenswerten Änderungen dieses Projektes werden in dieser Datei festgehalten.

## [1.6.3](x) - 2020-x-x

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
* Bug behoben, der den Index für die Scores falsch anlegte

### Deprecated

### Removed
* Dashboard "Statistiken" aus dem Netzwerkmenü entfernt
* Dashboard "Verbindungsüberwachung" aus dem Netzwerkmenü entfernt
* Dashboard "Windows Logs" aus dem Netzwerkmenü entfernt
* Dashboard "Systemmetriken Übersicht" aus dem Netzwerkmenü entfernt
* Dashboard "Systemmetriken Details" aus dem Netzwerkmenü entfernt
