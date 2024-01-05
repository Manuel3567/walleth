from flask import Flask, request, jsonify

app = Flask(__name__)

SERVICE_NAME = "admin"


@app.route(f"/{SERVICE_NAME}")
@app.route("/")
def index():
    path = request.path
    cookies = request.cookies
    result = {"path": path, "cookies": cookies, "service_name": SERVICE_NAME}

    return jsonify(result)


@app.route("/<path:custom_path>")
def custom(custom_path):
    path = "/" + custom_path if custom_path else "/"
    cookies = request.cookies
    result = {"path": path, "cookies": cookies, "service_name": SERVICE_NAME}

    return jsonify(result)


if __name__ == "__main__":
    app.run(debug=True)
