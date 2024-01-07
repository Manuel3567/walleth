import pytest
from flask import json
from app import app, get_user_document_from_email, delete_customer
from dotenv import load_dotenv
import os

load_dotenv()

@pytest.fixture
def client():
    app.config['TESTING'] = True
    client = app.test_client()

    # Setup: Add any necessary setup steps here

    yield client

    # Teardown: Add any necessary teardown steps here

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert 'service_name' in json.loads(response.data)

# Add more test functions for other endpoints and functionalities

def test_delete_customer(client):
    # Setup: Create a test user and customer in Firestore
    user_email = os.environ["EMAIL"]
    access_token = os.environ["TOKEN"]

    user_document = get_user_document_from_email(user_email)
    customer_name = 'c customer'
    user_document.collection('customers').document(customer_name).set({})

    # Test the DELETE endpoint
    data = {'customers': [{'name': customer_name}]}
    response = client.delete('/', json=data, headers={'Authorization': access_token})
    assert response.status_code == 200

    # Verify the customer has been deleted
    assert not user_document.collection('customers').document(customer_name).get().exists
    assert user_document.get().exists

    # Teardown: Remove the test user and customer from Firestore
    delete_customer(user_document, customer_name)

def test_create_and_get_customer(client):
    # Setup: Create a test user and customer in Firestore
    user_email = os.environ["EMAIL"]
    access_token = os.environ["TOKEN"]

    user_document = get_user_document_from_email(user_email)
    customer_name = 'd customer'

    data = {'customers': [{'name': customer_name}]}
    response = client.post('/', json=data, headers={'Authorization': access_token})
    assert response.status_code == 200
    customers = user_document.collection('customers')
    customer = customers.document(customer_name)
    assert customer.get().exists

    response = client.get('/', headers={'Authorization': access_token})
    assert response.status_code == 200
    result = response.get_json()
    assert result == {'customers': [{'name': customer_name, 'wallets': []}], 'email': user_email}

    # Teardown: Remove the test user and customer from Firestore
    delete_customer(user_document, customer_name)

def test_create_and_get_multiple_customers_with_wallets(client):
    # Setup: Create a test user and customer in Firestore
    user_email = os.environ["EMAIL"]
    access_token = os.environ["TOKEN"]

    user_document = get_user_document_from_email(user_email)
    customer_name = 'e customer'
    customer_name2 = 'f customer'

    data = {'customers': [{'name': customer_name},
                          {
                              'name': customer_name2,
                              'address': "abc-street",
                              'wallets': [
                                  {"account": "0x9aa99c23f67c81701c772b106b4f83f6e858dd2e"},
                                  {"account": "0xc5102fe9359fd9a28f877a67e36b0f050d81a3cc"}
                              ]
                              }
                          ]}
    response = client.post('/', json=data, headers={'Authorization': access_token})
    assert response.status_code == 200
    assert user_document.collection('customers').document(customer_name).get().exists
    assert user_document.collection('customers').document(customer_name2).get().exists

    response = client.get('/', headers={'Authorization': access_token})
    assert response.status_code == 200
    result = response.get_json()
    assert result == {"customers": [{}]}
    # Teardown: Remove the test user and customer from Firestore
    delete_customer(user_document, customer_name)