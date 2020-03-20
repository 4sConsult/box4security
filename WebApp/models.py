from WebApp import db, ma
# When in doubt, see:
# https://rahmanfadhil.com/flask-rest-api/


class BPFRule(db.Model):
    __tablename__ = 'blocks_by_bpffilter'
    id = db.Column(db.Integer, primary_key=True)
    src_ip = db.Column(db.String)
    src_port = db.Column(db.Integer)
    dst_ip = db.Column(db.String)
    dst_port = db.Column(db.Integer)
    proto = db.Column(db.String(4))


class LogstashRule(db.Model):
    __tablename__ = 'blocks_by_logstashfilter'
    id = db.Column(db.Integer, primary_key=True)
    src_ip = db.Column(db.String)
    src_port = db.Column(db.Integer)
    dst_ip = db.Column(db.String)
    dst_port = db.Column(db.Integer)
    proto = db.Column(db.String(4))
    signature_id = db.Column(db.String(10))
    signature = db.Column(db.String(256))


class BPFSchema(ma.Schema):
    class Meta:
        fields = ('id', 'src_ip', 'src_port', 'dst_ip', 'dst_port', 'proto')


class LSRSchema(ma.Schema):
    class Meta:
        fields = ('id', 'src_ip', 'src_port', 'dst_ip', 'dst_port', 'proto')


BPF = BPFSchema()
LSR = LSRSchema()
BPFs = BPFSchema(many=True)
LSRs = LSRSchema(many=True)
