from source.extensions import ma
from marshmallow import fields


class NetworkTypeSchema(ma.Schema):
    """Role Schema for API representation."""

    class Meta:
        """Define fields which will be available."""

        fields = ('id', 'name')


class ScanCategorySchema(ma.Schema):

    class Meta:
        fields = (
            'id',
            'name',
        )


class NetworkSchema(ma.Schema):

    types = fields.Nested(NetworkTypeSchema, many=True)
    scancategory = fields.Nested(ScanCategorySchema)

    class Meta:
        fields = (
            'id',
            'name',
            'ip_address',
            'cidr',
            'vlan',
            'types',
            'scancategory_id',
            'scan_weekday',
            'scan_time',
        )


class SystemTypeSchema(ma.Schema):
    """Role Schema for API representation."""

    class Meta:
        """Define fields which will be available."""

        fields = ('id', 'name')


class SystemSchema(ma.Schema):

    types = fields.Nested(SystemTypeSchema, many=True)
    scancategory = fields.Nested(ScanCategorySchema)
    network = fields.Nested(NetworkSchema)

    class Meta:
        fields = (
            'id',
            'name',
            'types',
            'network',
            'ip_address',
            'location',
            'scan_enabled',
            'ids_enabled',
        )


class BOX4securitySchema(ma.Schema):

    types = fields.Nested(SystemTypeSchema, many=True)
    scancategory = fields.Nested(ScanCategorySchema)
    network = fields.Nested(NetworkSchema)
    dns = fields.Nested(SystemSchema)
    gateway = fields.Nested(SystemSchema)

    class Meta:
        fields = (
            'id',
            'name',
            'types',
            'network',
            'ip_address',
            'location',
            'scan_enabled',
            'ids_enabled',
            'dhcp_enabled',
            'dns',
            'gateway',
        )


SYS = SystemSchema()
SYSs = SystemSchema(many=True)
BOX4sSchema = BOX4securitySchema()
NET = NetworkSchema()
NETs = NetworkSchema(many=True)
