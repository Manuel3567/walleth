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
APP_URL = os.environ.get("APP_URL", "https://app.portfolioeth.de")
TOKEN_AUDIENCE = os.environ.get("TOKEN_AUDIENCE", "https://api.app.portfolioeth.de")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "data")
AUTH0_DOMAIN = os.environ.get("AUTH0_DOMAIN", "dev-5u06wq701osq2uvn.us.auth0.com")
ETHEREUM_SERVICE_DOMAIN = os.environ.get("ETHEREUM_SERVICE_DOMAIN", "ethereum.dev.svc.cluster.local")

app = Flask(__name__)
CORS(app=app, origins=[APP_URL], supports_credentials=True)

import logging
app.logger.setLevel(logging.INFO)


db = firestore.Client()

@app.route("/health")
def index():
    path = request.path
    headers = dict(request.headers)
    cookies = request.cookies
    result = {"path": path, "headers": headers, "cookies": cookies, "service_name": SERVICE_NAME}

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

def get_and_verify_data_from_token(token):
    url = f"https://{AUTH0_DOMAIN}/.well-known/jwks.json"
    jwks_client = PyJWKClient(url)
    signing_key = jwks_client.get_signing_key_from_jwt(token)
    data = jwt.decode(
        token,
        signing_key.key,
        algorithms=["RS256"],
        audience=TOKEN_AUDIENCE,
        options={"verify_signature": True},
    )

    return data
    
def get_user_document_from_email(email) -> DocumentReference:
    document_name, collection_name = email.split('@')
    customer_document = db.collection(collection_name).document(document_name)
    return customer_document


def send_request_to_ethereum_service(data):
    # Send a POST request to the Ethereum service
    response = requests.post(ETHEREUM_SERVICE_DOMAIN, json=data)
    return response.json()

def get_customer_document_of(user_document, customer_name):
    customer_ref = user_document.collection('customers').document(customer_name)
    return customer_ref

def delete_wallet(user_document, customer_name, wallet_account):
    # Delete specific wallet and transactions from Firestore
    customer_ref = get_customer_document_of(user_document, customer_name)
    wallet_ref = customer_ref.collection('wallets').document(wallet_account)

    # Delete the wallet and its transactions
    wallet_ref.delete()

def delete_customer(user_document, customer_name):
    # Delete a customer and associated data from Firestore
    customer_ref = get_customer_document_of(user_document, customer_name)

    # Delete the customer and its wallets
    customer_ref.delete()

@app.route('/', methods=['GET', 'POST', 'PATCH', 'DELETE'])
def handle_requests():
    input_data = request.get_json()
    app.logger.info(f"{request.remote_addr} ({request.method}): {input_data}")
    try:
        access_token = request.headers.get('Authorization')
        access_token_data = get_and_verify_data_from_token(access_token)
        user_email = access_token_data["backend/email"]
    except jwt.ExpiredSignatureError:
        return jsonify(error="Valid access token is required"), 400
    except jwt.InvalidTokenError:
        return jsonify(error="Valid access token is required"), 400
    if not user_email:
        return jsonify(error="Valid access token is required"), 400

    # Query Firestore based on user details
    user_document = get_user_document_from_email(user_email)
    if request.method == 'GET':
        # Handle GET request
        
        try:
            user_data: DocumentSnapshot = user_document.get()
            if user_data.exists:
                return jsonify(user_data.to_dict())
            else:
                return jsonify(message="User not found"), 404

        except Exception as e:
            return jsonify(error=str(e)), 500

    elif request.method in ['POST', 'PATCH']:
        # Handle POST and PATCH requests
        # Check if the account has an empty balance or no transactions
        customers = input_data.get('customers', [])
        for customer in customers:
            missing_wallet_addresses = []
            wallets = customer.get('wallets', [])
            for wallet in wallets:
                if not wallet.get('balance') or not wallet.get('transactions'):
                    missing_wallet_addresses.append(wallet.account)
            # Make a POST request against the Ethereum service
            missing_data = send_request_to_ethereum_service(missing_wallet_addresses)
            for wallet in wallets:
                wallet_account_number = wallet.account
                if wallet_account_number in missing_data:
                    wallet["balance"] = missing_data[wallet_account_number]["balance"]               
                    wallet["transactions"] = missing_data[wallet_account_number]["transactions"]               

        # Store information in Firestore
        try:
            user_document.create()
        except Conflict:
            pass
        user_document.update(input_data)

        return {}, 200

    elif request.method == 'DELETE':
        # Handle DELETE request

        for customer in input_data.get('customers', []):
            customer_name = customer.get('name')

            if 'wallets' in customer:
                for wallet in customer['wallets']:
                    wallet_account = wallet.get('account')
                    delete_wallet(user_document, customer_name, wallet_account)
            else:
                delete_customer(user_document, customer_name)

        return {}, 200


if __name__ == "__main__":
    app.run(debug=True)
