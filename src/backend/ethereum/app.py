import os
import requests
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
from dataclasses import dataclass


APP_URL = os.environ.get("APP_URL", "https://app.portfolioeth.de")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "ethereum")
ETHERSCAN_API_KEY = os.environ.get("ETHERSCAN_API_KEY", "")

MAX_NUM_TRANSACTIONS = 550  # 10000 max


@dataclass
class BalanceResult:
    address: str
    balance: str


@dataclass
class BalancesResponse:
    status: str
    message: str
    result: list[BalanceResult]


@dataclass
class TransactionResult:
    blockNumber: str
    timeStamp: str
    hash: str
    nonce: str
    blockHash: str
    transactionIndex: str
    from_address: str
    to_address: str
    value: str
    gas: str
    gasPrice: str
    isError: str
    txreceipt_status: str
    input: str
    contractAddress: str
    cumulativeGasUsed: str
    gasUsed: str
    confirmations: str
    methodId: str
    functionName: str

    @classmethod
    def get(cls, **kwargs):
        from_address = kwargs.pop("from")
        to_address = kwargs.pop("to")
        input = kwargs.pop("input")
        if len(input) > 10:
            input = input[:10] + "..."  # limit to 10 chars to prevent db overload
        return cls(
            from_address=from_address, to_address=to_address, input=input, **kwargs
        )


@dataclass
class TransactionsResponse:
    status: str
    message: str
    result: list[TransactionResult]


app = Flask(__name__)
app.config["ETHERSCAN_API_KEY"] = ETHERSCAN_API_KEY

CORS(app=app, origins=[APP_URL], supports_credentials=True)


app.logger.setLevel(logging.INFO)


def parse_balances_response(data):
    app.logger.info(f"received etherscan data: {data}")
    return BalancesResponse(
        status=data.get("status"),
        message=data.get("message"),
        result=[
            BalanceResult(address=item.get("account"), balance=item.get("balance"))
            for item in data.get("result", [])
        ],
    )


@app.route("/balances", methods=["POST"])
def get_balances():
    api_key = app.config["ETHERSCAN_API_KEY"]
    try:
        data = request.get_json()
        app.logger.info(f"{request.remote_addr}: {data}")
        addresses = data.get("addresses")
        if not addresses:
            return jsonify({"error": "Addresses not provided"}), 400
        n = len(addresses)

        result = []
        for i in range(n // 20 + 1):
            ads = addresses[i * 20 : (i + 1) * 20]

            a = ",".join(ads)
            url = f"https://api.etherscan.io/api?module=account&action=balancemulti&address={a}&tag=latest&apikey={api_key}"

            response = requests.get(url)
            balance_data = response.json()

            balances_response = parse_balances_response(balance_data)
            result.extend(balances_response.result)
        return jsonify({"balances": result})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/transactions", methods=["POST"])
def get_transactions():
    api_key = app.config["ETHERSCAN_API_KEY"]
    try:
        data = request.get_json()
        app.logger.info(f"{request.remote_addr}: {data}")
        addresses = data.get("addresses")

        if not addresses:
            return jsonify({"error": "Addresses not provided"}), 400

        result = []
        for address in addresses:
            url = f"https://api.etherscan.io/api?module=account&action=txlist&address={address}&startblock=0&endblock=99999999&page=1&offset={MAX_NUM_TRANSACTIONS}&sort=desc&apikey={api_key}"
            response = requests.get(url)
            transactions_data = response.json()
            app.logger.info(f"received etherscan data: {transactions_data}")
            transactions_response = TransactionsResponse(
                status=transactions_data.get("status"),
                message=transactions_data.get("message"),
                result=[
                    TransactionResult.get(**r)
                    for r in transactions_data.get("result", [])
                ],
            )
            transactions = transactions_response.result
            result.append({"address": address, "transactions": transactions})

        return jsonify({"transactions": result})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/health")
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


if __name__ == "__main__":
    app.run(debug=True)
