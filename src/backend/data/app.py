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
TOKEN_AUDIENCE = os.environ.get("TOKEN_AUDIENCE", "")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "data")
AUTH0_DOMAIN = os.environ.get("AUTH0_DOMAIN", "")
ETHEREUM_SERVICE_DOMAIN = os.environ.get("ETHEREUM_SERVICE_DOMAIN", "")

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
    user, domain = email.split('@')
    user_document_ref = db.collection("domains").document(domain).collection("users").document(user)
    return user_document_ref


def send_request_to_ethereum_service(addresses):
    data = {"addresses": addresses}
    # Send a POST request to the Ethereum service
    response = requests.post(f"http://{ETHEREUM_SERVICE_DOMAIN}/balances", json=data)
    balances = response.json()["balances"]
    response = requests.post(f"http://{ETHEREUM_SERVICE_DOMAIN}/transactions", json=data)
    transactions = response.json()["transactions"]

    result = {}
    for account in balances:
        result[account["account"]] = account["balance"]

    for account in transactions:
        addr = account.pop("account")
        result[addr] = {**result[addr], **account}

    return result

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

def get_document_and_subcollections(document_ref):
    result = {}

    # Get the data of the current document
    document_data = document_ref.get().to_dict()
    if document_data:
        result.update(document_data)

    # Get subcollections
    subcollections = document_ref.collections()

    for subcollection in subcollections:
        # Recursively get data for each subcollection
        subcollection_data = get_document_and_subcollections(subcollection)
        
        # Add subcollection data to the result
        subcollection_name = subcollection.id
        result[subcollection_name] = subcollection_data

    return result

@app.route('/', methods=['GET', 'POST', 'PATCH', 'DELETE'])
def handle_requests():
    app.logger.info(f"{request.remote_addr} ({request.method})")
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
    user_document_ref = get_user_document_from_email(user_email)
    if request.method == 'GET':
        # Handle GET request
        result = user_document_ref.get().to_dict()
        result["customers"] = []
        customers = result["customers"]
        customers_ref = user_document_ref.collection("customers")
        for customer_ref in customers_ref.list_documents():
            customer: dict = customer_ref.get().to_dict()
            wallets_ref = customer_ref.collection("wallets")
            wallets = []
            for wallet_ref in wallets_ref.list_documents():
                wallet = wallet_ref.get().to_dict()
                wallets.append(wallet)
            customer["wallets"] = wallets
            customers.append(customer)
        

        return jsonify(result)

    elif request.method in ['POST', 'PATCH']:
        # Handle POST and PATCH requests
        # Check if the account has an empty balance or no transactions
        input_data = request.get_json()
        app.logger.info(f"{request.remote_addr} ({request.method}): {input_data}")
        customers = input_data.get('customers', [])
        user_document_ref.set({"email": user_email})
        customers_ref = user_document_ref.collection("customers")

        for customer in customers:
            customer_ref = customers_ref.document(customer["name"])
            customer_ref.set({"name": customer["name"]})
            wallets_ref = customer_ref.collection("wallets")


            missing_wallet_addresses = []
            wallets = customer.get('wallets', [])
            for wallet in wallets:
                account = wallet["account"]
                wallet_ref = wallets_ref.document(account)
                wallet_ref.set({"account": account})
                if not wallet.get('balance') or not wallet.get('transactions'):
                    missing_wallet_addresses.append(account)
                    wallet_ref.set({"balance": None, "transactions": None})
                else:
                    wallet_ref.set({"balance": wallet.get('balance'), "transactions": wallet.get('transactions')})

            if not missing_wallet_addresses:
                continue
            # Make a POST request against the Ethereum service
            missing_data = send_request_to_ethereum_service(missing_wallet_addresses)

            for wallet_account_number in missing_wallet_addresses:
                wallet_ref = wallets_ref.collection(wallet_account_number)
                wallet_ref.set(
                    {
                        "balance": missing_data[wallet_account_number]["balance"],
                        "transactions": missing_data[wallet_account_number]["transactions"]
                    }
                )           

        # Store information in Firestore
        # c = {customer["name"]: customer for customer in customers}
        # input_data["customers"] = c
        # for customer in customers:
        # try:
        #     user_document.collection("customers").set(c)
        #     #user_document.create(input_data)
        # except Conflict as e:
        #     user_document.update(input_data)

        # except Exception as e:
        #     app.logger.error(e)
        #     return {}, 500

        return {}, 200

    elif request.method == 'DELETE':
        # Handle DELETE request
        input_data = request.get_json()

        for customer in input_data.get('customers', []):
            customer_name = customer.get('name')

            if 'wallets' in customer:
                for wallet in customer['wallets']:
                    wallet_account = wallet.get('account')
                    delete_wallet(user_document_ref, customer_name, wallet_account)
            else:
                delete_customer(user_document_ref, customer_name)

        return {}, 200


if __name__ == "__main__":
    app.run(debug=True)
