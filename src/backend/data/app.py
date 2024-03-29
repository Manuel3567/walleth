from flask import Flask, request, jsonify
from flask_cors import CORS

import os
import requests
import jwt
from jwt import PyJWKClient
from google.cloud import firestore
from google.cloud.firestore_v1 import DocumentSnapshot, DocumentReference
from google.cloud.exceptions import Conflict
from dataclasses import dataclass


# Use the service account key file for authentication

APP_URL = os.environ.get("APP_URL", "")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "data")
AUTH0_DOMAIN = os.environ.get("AUTH0_DOMAIN", "")
ETHEREUM_SERVICE_DOMAIN = os.environ.get("ETHEREUM_SERVICE_DOMAIN", "")
TOKEN_AUDIENCE = os.environ.get("TOKEN_AUDIENCE", "")
app = Flask(__name__)
CORS(
    app=app,
    origins=[APP_URL, "http://localhost:3000", "localhost:3000"],
    supports_credentials=True,
)


import logging

app.logger.setLevel(logging.INFO)


@app.route("/")
@app.route("/health")
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


@dataclass
class BalanceResult:
    account: str
    balance: str


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


def get_and_verify_data_from_token(token, auth0_domain, token_audience):
    url = f"https://{auth0_domain}/.well-known/jwks.json"
    jwks_client = PyJWKClient(url)
    signing_key = jwks_client.get_signing_key_from_jwt(token)
    data = jwt.decode(
        token,
        signing_key.key,
        algorithms=["RS256"],
        audience=token_audience,
        options={"verify_signature": True},
    )

    return data


def get_user_document_from_email(email) -> DocumentReference:
    user, domain = email.split("@")
    db = firestore.Client()
    user_document_ref = (
        db.collection("domains").document(domain).collection("users").document(user)
    )
    return user_document_ref


def get_customer_names_from_user_email(email) -> list[str]:
    doc_ref = get_user_document_from_email(email)
    customer_names = []
    for customer_ref in doc_ref.collection("customers").list_documents():
        customer_name = customer_ref.path.split("/")[-1]
        customer_names.append(customer_name)
    return customer_names


def send_request_to_ethereum_service(addresses):
    data = {"addresses": addresses}
    # Send a POST request to the Ethereum service
    response = requests.post(f"http://{ETHEREUM_SERVICE_DOMAIN}/balances", json=data)
    balances = response.json()["balances"]
    response = requests.post(
        f"http://{ETHEREUM_SERVICE_DOMAIN}/transactions", json=data
    )
    transactions = response.json()["transactions"]

    result = {}
    for balance in balances:
        addr = balance.get("address")
        result[addr] = balance

    for transaction in transactions:
        addr = transaction.get("address")
        result[addr] = {**result[addr], **transaction}

    return result


def get_customer_document_of(user_document, customer_name):
    customer_ref = user_document.collection("customers").document(customer_name)
    return customer_ref


def delete_wallet(user_document, customer_name, wallet_address):
    # Delete specific wallet and transactions from Firestore
    customer_ref = get_customer_document_of(user_document, customer_name)
    wallet_ref = customer_ref.collection("wallets").document(wallet_address)

    # Delete the wallet and its transactions
    wallet_ref.delete()


def delete_customer(user_document, customer_name):
    # Delete a customer and associated data from Firestore
    customer_ref = get_customer_document_of(user_document, customer_name)
    wallets_coll_ref = customer_ref.collection("wallets")
    for wallet_ref in wallets_coll_ref.list_documents():
        wallet_ref.delete()
    # Delete the customer and its wallets
    customer_ref.delete()


@app.route(f"/{SERVICE_NAME}/", methods=["GET", "POST", "PATCH", "DELETE"])
def handle_requests():
    app.logger.info(f"{request.remote_addr} ({request.method})")
    try:
        bearer = request.headers.get(
            "Authorization"
        )  # oauth2 requires header Authorization: Bearer ey...
        access_token = bearer.split()[1]
        access_token_data = get_and_verify_data_from_token(
            access_token, auth0_domain=AUTH0_DOMAIN, token_audience=TOKEN_AUDIENCE
        )
        user_email = access_token_data["backend/email"]
    except jwt.ExpiredSignatureError:
        return jsonify(error="Valid access token is required"), 400
    except jwt.InvalidTokenError:
        return jsonify(error="Valid access token is required"), 400
    if not user_email:
        return jsonify(error="Valid access token is required"), 400

    # Query Firestore based on user details
    user_document_ref = get_user_document_from_email(user_email)
    if request.method == "GET":
        app.logger.info("Executing GET")
        # Handle GET request
        user = user_document_ref.get().to_dict()  # can be None
        if user is None:
            user = dict()
        user["customers"] = []
        customers = user["customers"]
        customers_ref = user_document_ref.collection("customers")
        app.logger.info("Accessing user's customer data...")
        for customer_ref in customers_ref.list_documents():
            customer: dict = customer_ref.get().to_dict()
            if not isinstance(customer, dict):
                app.logger.warning(
                    f"customer: {customer_ref.path} could not be converted to a dict. Deleting customer"
                )
                delete_customer(user_document_ref, customer_ref.path.split("/")[-1])
                customer_ref.delete()
                continue
            wallets_ref = customer_ref.collection("wallets")
            wallets = []
            for wallet_ref in wallets_ref.list_documents():
                wallet = wallet_ref.get().to_dict()
                if not isinstance(wallet, dict):
                    app.logger.warning(
                        f"wallet: {wallet_ref.path} could not be converted to a dict. Deleting wallet..."
                    )
                    wallet_ref.delete()
                    continue
                wallets.append(wallet)
            customer["wallets"] = wallets
            customers.append(customer)

        return jsonify(user)

    elif request.method in ["POST", "PATCH"]:
        # Handle POST and PATCH requests
        input_data = request.get_json()
        app.logger.info(f"{request.remote_addr} ({request.method}): {input_data}")
        customers = input_data.get("customers", [])
        user_document_ref.set({"email": user_email})
        customers_ref = user_document_ref.collection("customers")

        for customer in customers:
            customer_ref = customers_ref.document(customer["name"])
            customer_ref.set(
                {
                    "name": customer["name"],
                    "email": customer.get("email", ""),
                    "phone": customer.get("phone", ""),
                    "address": customer.get("address", ""),
                }
            )
            wallets_ref = customer_ref.collection("wallets")

            missing_wallet_addresses = []
            wallets = customer.get("wallets", [])
            for wallet in wallets:
                if not isinstance(wallet, dict):
                    continue
                if "address" not in wallet:
                    continue
                address = wallet["address"]
                wallet_ref = wallets_ref.document(address)
                if not wallet.get("balance") or not wallet.get("transactions"):
                    missing_wallet_addresses.append(address)
                    wallet_ref.set(
                        {"address": address, "balance": None, "transactions": None}
                    )
                else:
                    wallet_ref.set(
                        {
                            "address": address,
                            "balance": wallet.get("balance"),
                            "transactions": wallet.get("transactions"),
                        }
                    )

            if not missing_wallet_addresses:
                continue
            # Make a POST request against the Ethereum service
            missing_data = send_request_to_ethereum_service(missing_wallet_addresses)

            for wallet_address in missing_wallet_addresses:
                wallet_ref = wallets_ref.document(wallet_address)
                wallet_ref.set(
                    {
                        "address": wallet_address,
                        "balance": missing_data[wallet_address]["balance"],
                        "transactions": missing_data[wallet_address]["transactions"],
                    }
                )

        return {}, 200

    elif request.method == "DELETE":
        # Handle DELETE request
        input_data = request.get_json()
        app.logger.info(f"{request.remote_addr} ({request.method}): {input_data}")

        for customer in input_data.get("customers", []):
            customer_name = customer.get("name")

            if "wallets" in customer:
                for wallet in customer["wallets"]:
                    wallet_address = wallet.get("address")
                    app.logger.info(
                        f"Deleting customer {customer_name}'s wallet: {wallet_address}"
                    )
                    delete_wallet(user_document_ref, customer_name, wallet_address)
            else:
                app.logger.info(f"Deleting customer {customer_name}")
                delete_customer(user_document_ref, customer_name)

        return {}, 200


if __name__ == "__main__":
    app.run(debug=True)
