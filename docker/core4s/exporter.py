#!/bin/python3
from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print
import xml.etree.ElementTree as ET
import untangle
import base64
import configparser
CONFIG_PATH = '/core4s/config/secrets/openvas.conf'

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
        base64CSV = untangledReport.get_reports_response.report.cdata
        data = str(base64.b64decode(base64CSV), 'utf-8')
        writeReport(resultId, data)
        numWritten += 1
    return numWritten


def writeReport(resultId, data):
    pass


connection = TLSConnection(hostname="openvas", port=9390)
with Gmp(connection) as gmp:
    gmp.authenticate(config['config']['OPENVAS_USER'], config['config']['OPENVAS_PASS'])
    reportFormatId = getReportFormat()
    reportIds = getReportIds()
    numWritten = handleReports(reportIds, reportFormatId)
    print("{numWritten} vulnerabiltity reports written to disk.")