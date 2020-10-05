#!/bin/python3
from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp
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


def transformReport(reportData):
    """Apply transformations to the `reportData` to keep the original data structure of ES index and Logstash.

    The transformations are merely a renaming of document keys."""
    transformedReport = dict()
    dictTransform = {
        'IP': 'asset',
        'Hostname': 'hostname',
        'Port': 'port',
        'Port Protocol': 'protocol',
        'CVSS': 'cvss',
        'Severity': 'severity',
        'Solution Type': 'category',
        'NVT Name': 'plugin_name',
        'Summary': 'synopsis',
        'Specific Result': 'plugin_output',
        'NVT OID': 'nvt_oid',
        'CVEs': 'CVEs',
        'Task ID': 'task_id',
        'Task Name': 'task_name',
        'Timestamp': 'timestamp',
        'Result ID': 'result_id',
        'Impact': 'description',
        'Solution': 'solution',
        'Affected Software/OS': 'affected_software',
        'Vulnerability Insight': 'vulnerability_insight',
        'Vulnerability Detection Method': 'vulnerability_detection_method',
        "Product Detection Result": 'product_detection_result',
        'BIDs': 'bids',
        'CERTs': 'certs',
        'Other References': 'see_also',
    }
    for k in reportData:
        # Iterate over keys
        try:
            # Try to apply the transformations as defined in the transformation dictionary.
            transformedK = dictTransform[k]
        except KeyError:
            transformedK = k
            # Non existent transformation for k.
            # Display a warning. Output of logs can be forwarded for later implementation.
            print('#### WARNING ####')
            print(f'Transformation for key "{k}" not found!!')
            print('\n')
        # Create new dictionary from transformed keys and keeping the original data.
        transformedReport[transformedK] = reportData[k]
    return transformedReport


def getReportFormat():
    """Get the CSV result format identifier from OpenVAS XML API."""
    reportFormats = gmp.get_report_formats()
    root = ET.fromstring(reportFormats)
    # Use XPath instruction to find the report format and extract its id.
    return root.find("./report_format[name='CSV Results']").attrib.get('id')


def getReportIds():
    """Get the report ids from OpenVAS XML API."""
    reports = []
    allReports = gmp.get_reports()  # Fetch all reports.
    root = ET.fromstring(allReports)
    # Iterate over all reports and append their ids to the `reports` list.
    for document in root:
        if document.tag == 'report':
            for report in document:
                if report.tag == 'report':
                    reports.append(document.attrib.get('id'))
    return reports


def handleReports(reportIds, reportFormatId):
    """Handle the list of `reportIDs`.

    This is the core function.
    The function iterates over all `reportIds` and queries the relevant reports with all details from OpenVAS. This may take some time.
    First it is checked if the `reportId` has been processed before. If yes, the report is skipped to avoid overhead.
    Then the result XML is "untangled" into a Python object.
    The `reportFormatId` is used to specify that a CSV response is wanted.
    The CSV comes base64 encoded and must be decoded.
    Return a tuple of two integers (numWritten, numSkipped)
    of the reports written to disk or the skipped reports because they have been processed previously"""
    numWritten = 0
    numSkipped = 0
    for reportId in reportIds:
        if isReportFresh(reportId):
            formattedReport = gmp.get_report(reportId, report_format_id=reportFormatId, filter="apply_overrides=0 min_qod=70", ignore_pagination=True, details=True)
            untangledReport = untangle.parse(formattedReport)
            resultId = untangledReport.get_reports_response.report['id']
            base64CSV = untangledReport.get_reports_response.report.cdata
            # decode the CSV from base64.
            data = str(base64.b64decode(base64CSV), 'utf-8')
            try:
                # Convert the report's creation date to a UNIX timestamp:
                reportTimestamp = int(time.mktime(time.strptime(untangledReport.get_reports_response.report.creation_time.cdata, '%Y-%m-%dT%H:%M:%SZ')))
            except ValueError:
                # Failed getting the report's creation date. Use current timestamp as a fallback.
                reportTimestamp = int(time.time())
            # Call the function to write the report to disk.
            writeReport(resultId, data, reportTimestamp)
            numWritten += 1
        else:
            numSkipped += 1
    return (numWritten, numSkipped)


def writeReport(resultId, data, reportTimestamp):
    """Write the report `resultId` with content `data` to disk.
    The file will be written to `REPORTS_PATH`/openvas_scan_`reportTimestamp`_`resultId`.json.
    Mark the report as processed by adding the `resultId` to the sqlite3 database `DB_PATH`."""
    # Parse data as csv
    csvReader = csv.DictReader(data.splitlines())
    # Set the filename from the `REPORT_NAME_TEMPLATE`
    fileName = REPORT_NAME_TEMPLATE.format(
        reportTimestamp,
        resultId.replace('-', '')
    )
    # Create a path from the `REPORTS_PATH` and new `fileName` and open the file writable.
    with open(path.join(REPORTS_PATH, fileName), "w") as jsonFile:
        for csvRow in csvReader:
            # Parse the csv row by row and apply transformations on each row.
            transformedData = transformReport(csvRow)
            # Finally write the data to disk as in JSON.
            jsonFile.write(json.dumps(transformedData))
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


# Prepare TLS Connection to OpenVAS XML API.
# Timeout=None is necessary because OpenVAS API can take a long time to generate the XML reports.
connection = TLSConnection(hostname="openvas", port=9390, timeout=None)
# Connect to local sqlite3 db
dbConn = sqlite3.connect(DB_PATH)
dbCursor = dbConn.cursor()
# Create the needed table if it does not exist:
dbCursor.execute('''CREATE TABLE IF NOT EXISTS `reports` ([id] INTEGER PRIMARY KEY AUTOINCREMENT,[resultId] text)''')
dbConn.commit()
# Create the needed index on the table if it does not exist. Useful for speeding up lookups on `resultId` in isReportFresh.
dbCursor.execute('''CREATE INDEX IF NOT EXISTS `reports_by_ids` on `reports`([resultId])''')
dbConn.commit()

# Open the OpenVAS GMP connection and authenticate.
with Gmp(connection) as gmp:
    gmp.authenticate(config['config']['OPENVAS_USER'], config['config']['OPENVAS_PASS'])
    reportFormatId = getReportFormat()   # Get the identifier for the CSV report format.
    reportIds = getReportIds()  # Get all report ids.
    (numWritten, numSkipped) = handleReports(reportIds, reportFormatId)  # Handle the reports (write to disk if new).
    print(f"{numWritten} vulnerabiltity reports written to disk. {numSkipped} reports have been collected previously and were skipped now.")

# Close the connection once the script is done.
dbConn.commit()
dbConn.close()
