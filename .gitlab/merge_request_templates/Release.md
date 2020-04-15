#### Release Candidate Checkliste
- [ ] Prüfung der Installation
- [ ] Prüfung des Updates von der vorherigen Version
- [ ] RC-Tag erstellen
- [ ] Dockerimages neu erstellen
  - [ ] Images mit dem neuen RC-Tag taggen
  - [ ] Images in die Docker Registry pushen
- [ ] Changelog überarbeiten
- [ ] Merges begutachten / schließen
- [ ] Story Points berechnen
- [ ] Sprint Goal prüfen
- [ ] Issues in den Product Backlog überführen

#### Release Checkliste
- [ ] Versions-Tag erstellen
- [ ] Dockerimages mit der neuen Version taggen
- [ ] Images in die Docker Registry pushen
- [ ] Versionsnummer in [VERSION](VERSION) ändern
- [ ] Alte Branches löschen
- [ ] Updateskript leeren
- [ ] Dockerimage Tag zuletzt wieder auf `dev` setzen
