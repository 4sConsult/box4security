from flask import Flask
from flask_restful import Resource, Api


app = Flask(__name__)
api = Api(app)


class Rule(Resource):
    def get(self):
        return {'hello': 'world'}

    def post(self):
        return {}

    def put(self):
        return {}

    def delete(self):
        return {}


class Alert(resource):
    def get(self):
        return {}

    def post(self):
        return {}

    def put(self):
        return {}

    def delete(self):
        return {}


api.add_resource(Rule, '/rule')
api.add_resource(Alert, '/alert')

if __name__ == '__main__':
    app.run(debug=True)
