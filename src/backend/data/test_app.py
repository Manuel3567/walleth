import pytest
from flask import json
from app import (
    app,
    get_user_document_from_email,
    delete_customer,
    get_and_verify_data_from_token,
)
from dotenv import load_dotenv
import os

load_dotenv()


@pytest.fixture
def client():
    app.config["TESTING"] = True
    client = app.test_client()

    # Setup: Add any necessary setup steps here

    yield client

    # Teardown: Add any necessary teardown steps here


@pytest.fixture(scope="function")
def user_document():
    user_email = os.environ["EMAIL"]
    user_document = get_user_document_from_email(user_email)
    yield user_document
    user_document.delete()


def test_health_endpoint(client):
    response = client.get("/")
    assert response.status_code == 200
    assert "service_name" in json.loads(response.data)


def test_get_and_verify_data_from_token():
    data = get_and_verify_data_from_token(
        os.environ["TOKEN"], os.environ["AUTH0_DOMAIN"], os.environ["TOKEN_AUDIENCE"]
    )


def test_delete_customer(client, user_document):
    # Setup: Create a test user and customer in Firestore
    access_token = os.environ["TOKEN"]

    customer_name = "c customer"
    user_document.collection("customers").document(customer_name).set({})

    # Test the DELETE endpoint
    data = {"customers": [{"name": customer_name}]}
    response = client.delete("/", json=data, headers={"Authorization": access_token})
    assert response.status_code == 200

    # Verify the customer has been deleted
    assert (
        not user_document.collection("customers").document(customer_name).get().exists
    )


def test_create_and_get_customer(client, user_document):
    # Setup: Create a test user and customer in Firestore
    user_email = os.environ["EMAIL"]
    access_token = os.environ["TOKEN"]

    customer_name = "d customer"

    data = {"customers": [{"name": customer_name}]}
    response = client.post("/", json=data, headers={"Authorization": access_token})
    assert response.status_code == 200
    customers = user_document.collection("customers")
    customer = customers.document(customer_name)
    assert customer.get().exists

    response = client.get("/", headers={"Authorization": access_token})
    assert response.status_code == 200
    result = response.get_json()
    assert result["email"] == user_email
    assert result["customers"][0] == {"name": customer_name, "wallets": []}


def test_create_and_get_multiple_customers_with_wallets(client, user_document):
    # Setup: Create a test user and customer in Firestore
    user_email = os.environ["EMAIL"]
    access_token = os.environ["TOKEN"]

    customer_name = "e customer"
    customer_name2 = "f customer"

    data = {
        "customers": [
            {"name": customer_name},
            {
                "name": customer_name2,
                "address": "abc-street",
                "wallets": [
                    {"account": "0x9aa99c23f67c81701c772b106b4f83f6e858dd2e"},
                    {"account": "0xc5102fe9359fd9a28f877a67e36b0f050d81a3cc"},
                ],
            },
        ]
    }
    response = client.post("/", json=data, headers={"Authorization": access_token})
    assert response.status_code == 200
    assert user_document.collection("customers").document(customer_name).get().exists
    assert user_document.collection("customers").document(customer_name2).get().exists

    response = client.get("/", headers={"Authorization": access_token})
    assert response.status_code == 200
    result = response.get_json()
    assert result["email"] == user_email
    assert set(result["customers"][-1]["wallets"][0].keys()) == {
        "balance",
        "transactions",
    }