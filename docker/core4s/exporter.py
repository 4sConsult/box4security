#!/bin/python3
from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print
import xml.etree.ElementTree as ET
from os import path
import time
import csv
import json
import untangle
import base64
import configparser
import sqlite3
CONFIG_PATH = '/core4s/config/secrets/openvas.conf'
REPORTS_PATH = '/core4s/workfolder/var/lib/logstash/openvas/'
DB_PATH = '/core4s/workfolder/var/lib/box4s/processed_vulns.db'
REPORT_NAME_TEMPLATE = 'openvas_scan_{0}_{1}.json'

config = configparser.ConfigParser()
with open(CONFIG_PATH, 'r') as f:
    config_string = '[config]\n' + f.read()
config.read_string(config_string)


def getReportFormat():
    """Get the CSV result format identifier from OpenVAS XML API."""
    reportFormats = gmp.get_report_formats()
    root = ET.fromstring(reportFormats)
    for document in root:
        for reportFormat in document:
            if reportFormat.text == 'CSV result list.':
                return document.attrib.get('id')


def getReportIds():
    """Get the report ids from OpenVAS XML API."""
    reports = []
    allReports = gmp.get_reports()
    root = ET.fromstring(allReports)
    for document in root:
        if document.tag == 'report':
            for report in document:
                if report.tag == 'report':
                    reports.append(report.attrib.get('id'))
    return reports


def handleReports(reportIds, reportFormatId):
    numWritten = 0
    numSkipped = 0
    for reportId in reportIds:
        if isReportFresh(reportId):
            formattedReport = gmp.get_report(reportId, report_format_id=reportFormatId, filter="apply_overrides=0 min_qod=70", ignore_pagination=True, details=True)
            print(formattedReport)
            untangledReport = untangle.parse(formattedReport)
            resultId = untangledReport.get_reports_response.report['id']
            base64CSV = untangledReport.get_reports_response.report.cdata
            data = str(base64.b64decode(base64CSV), 'utf-8')
            writeReport(resultId, data)
            numWritten += 1
        else:
            numSkipped += 1
    return (numWritten, numSkipped)


def writeReport(resultId, data):
    """Write the report `resultId` with content `data` to disk.
    The file will be written to `REPORTS_PATH`/openvas_scan_TIMESTAMP_`resultId`.json
    Mark the report as processed by adding the `resultId` to the sqlite3 database `DB_PATH`."""
    # Parse data as csv
    print(data)
    csvReader = csv.DictReader(data.splitlines())
    fileName = REPORT_NAME_TEMPLATE.format(
        int(time.time()),
        resultId.replace('-', '')
    )
    with open(path.join(REPORTS_PATH, fileName), "w") as jsonFile:
        for csvRow in csvReader:
            jsonFile.write(json.dumps(csvRow))
            jsonFile.write('\n')

    # Mark the report as processed.
    dbCursor.execute('''INSERT INTO `reports`(resultId) VALUES(?)''', (resultId, ))
    dbConn.commit()


def isReportFresh(resultId):
    """"Check if the report with id resultId is new.

    Return true if the resultId does not exist in the sqlite3 database `DB_PATH` else false."""
    dbCursor.execute("SELECT COUNT(*) FROM `reports` WHERE resultId=?", (resultId, ))
    count = dbCursor.fetchone()[0]
    return count == 0


# Prepare TLS Connection to OpenVAS XML API
connection = TLSConnection(hostname="openvas", port=9390, timeout=None)
# Connect to local sqlite3 db
dbConn = sqlite3.connect(DB_PATH)
dbCursor = dbConn.cursor()
# Create the needed table if it does not exist:
dbCursor.execute('''CREATE TABLE IF NOT EXISTS `reports` ([id] INTEGER PRIMARY KEY AUTOINCREMENT,[resultId] text)''')
dbConn.commit()
dbCursor.execute('''CREATE INDEX IF NOT EXISTS `reports_by_ids` on `reports`([resultId])''')
dbConn.commit()

with Gmp(connection) as gmp:
    gmp.authenticate(config['config']['OPENVAS_USER'], config['config']['OPENVAS_PASS'])
    reportFormatId = getReportFormat()
    reportIds = getReportIds()
    (numWritten, numSkipped) = handleReports(reportIds, reportFormatId)
    print(f"{numWritten} vulnerabiltity reports written to disk. {numSkipped} reports have been collected previously and were skipped now.")

# Close the connection once the script is done.
dbConn.commit()
dbConn.close()
