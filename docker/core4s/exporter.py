#!/bin/python3
from gvm.connctions import TLSConnection
from gvm.protocols.gmp import Gmp 
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print
import xml.etree.ElementTree as ET
import untangle

connection = TLSConnection(hostname="openvas")
username = "admin"
password = "admin"


def exportReports():
    with Gmp(connection) as gmp:
        gmp.authenticate(username, password)
        reportFormat = gmp.get_report_formats()
        pretty_print(reportFormat)
