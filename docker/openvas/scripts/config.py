from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print
import os

conn = TLSConnection()
transform = EtreeTransform()

with Gmp(conn, transform=transform) as gmp:
    # Login
    gmp.authenticate(os.getenv('OPENVAS_USER'), os.getenv('OPENVAS_PASS'))
    with open('/etc/openvas/4s-OpenVAS.xml', 'r') as fxml:
        xml_string = fxml.read()
        gmp.import_config(xml_string)
