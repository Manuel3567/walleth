from flask import Flask, request, jsonify
from flask_cors import CORS

import os

APP_URL = os.environ.get("APP_URL", "https://app.portfolioeth.de")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "data")

app = Flask(__name__)
CORS(app=app, origins=[APP_URL], supports_credentials=True)


@app.route(f"/{SERVICE_NAME}")
@app.route("/")
def index():
    path = request.path
    headers = dict(request.headers)
    cookies = request.cookies
    result = {
        "path": path,
        "headers": headers,
        "cookies": cookies,
        "service_name": SERVICE_NAME,
    }

    return jsonify(result)


@app.route("/<path:custom_path>")
def custom(custom_path):
    path = "/" + custom_path if custom_path else "/"
    cookies = request.cookies
    result = {"path": path, "cookies": cookies, "service_name": SERVICE_NAME}

    return jsonify(result)


if __name__ == "__main__":
    app.run(debug=True)
