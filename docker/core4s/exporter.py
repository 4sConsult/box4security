#!/bin/python3
from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp 
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print
import xml.etree.ElementTree as ET
import untangle
import configparser
CONFIG_PATH = '/core4s/config/secrets/openvas.conf'

config = configparser.ConfigParser()
with open(CONFIG_PATH, 'r') as f:
    config_string = '[config]\n' + f.read()
config.read_string(config_string)


connection = TLSConnection(hostname="openvas", port=9390)
def exportReports():
    with Gmp(connection) as gmp:
        gmp.authenticate(config['config']['OPENVAS_USER'], config['config']['OPENVAS_PASS'])
        reportFormat = gmp.get_report_formats()
        pretty_print(reportFormat)

exportReports()