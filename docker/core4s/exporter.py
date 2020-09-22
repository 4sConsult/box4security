#!/bin/python3
from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print
import xml.etree.ElementTree as ET
import untangle
import base64
import configparser
import sqlite3
CONFIG_PATH = '/core4s/config/secrets/openvas.conf'
DB_PATH = '/core4s/workfolder/var/lib/box4s/processed_vulns.db'

config = configparser.ConfigParser()
with open(CONFIG_PATH, 'r') as f:
    config_string = '[config]\n' + f.read()
config.read_string(config_string)


def getReportFormat():
    reportFormats = gmp.get_report_formats()
    root = ET.fromstring(reportFormats)
    for document in root:
        for reportFormat in document:
            if reportFormat.text == 'CSV result list.':
                return document.attrib.get('id')


def getReportIds():
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
    for reportId in reportIds:
        formattedReport = gmp.get_report(reportId, report_format_id=reportFormatId, filter="apply_overrides=0 min_qod=70", ignore_pagination=True, details=True)
        untangledReport = untangle.parse(formattedReport)
        resultId = untangledReport.get_reports_response.report['id']
        if isReportFresh(resultId):
            base64CSV = untangledReport.get_reports_response.report.cdata
            data = str(base64.b64decode(base64CSV), 'utf-8')
            writeReport(resultId, data)
            numWritten += 1
    return numWritten


def writeReport(resultId, data):
    dbCursor.execute('''INSERT INTO `reports`(resultId) VALUES(?)''', (resultId, ))
    dbConn.commit()


def isReportFresh(resultId):
    dbCursor.execute("SELECT EXISTS(SELECT 1 FROM `reports` WHERE resultId=?)", (resultId, ))
    return not dbCursor.fetchone()


# Prepare TLS Connection to OpenVAS XML API
connection = TLSConnection(hostname="openvas", port=9390)
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
    numWritten = handleReports(reportIds, reportFormatId)
    print(f"{numWritten} vulnerabiltity reports written to disk.")

# Close the connection once the script is done.
dbConn.commit()
dbConn.close()
