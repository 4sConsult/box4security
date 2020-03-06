from gvm.connections import TLSConnection
from gvm.protocols.gmp import Gmp
from gvm.transforms import EtreeTransform
from gvm.xml import pretty_print

conn = TLSConnection()
transform = EtreeTransform()

with Gmp(conn, transform=transform) as gmp:
    # Login
    gmp.authenticate('amadmin', '27d55284-90c8-4cc6-9a3e-01763bdab69a')
    with open('/home/amadmin/box4s/BOX4s-main/4s-OpenVAS.xml', 'r') as fxml:
        xml_string = fxml.read()
        gmp.import_config(xml_string)
