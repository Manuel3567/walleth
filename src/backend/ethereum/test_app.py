import json
import pytest
import os
from app import app
from dotenv import load_dotenv

load_dotenv()
env = os.environ


@pytest.fixture
def client():
    app.config["TESTING"] = True
    app.config["ETHERSCAN_API_KEY"] = os.environ[
        "ETHERSCAN_API_KEY"
    ]  # Set a test API key for testing purposes
    with app.test_client() as client:
        yield client


def test_get_balances(client):
    data = {"addresses": ["0xddBd2B932c763bA5b1b7AE3B362eac3e8d40121A"]}
    response = client.post(
        "/balances", data=json.dumps(data), content_type="application/json"
    )
    print(f"Etherscan API Response (get_balances): {response.json}")
    assert response.status_code == 200
    assert "balances" in response.json


def test_get_balances_invalid_input(client):
    data = {"invalid_key": "invalid_value"}
    response = client.post(
        "/balances", data=json.dumps(data), content_type="application/json"
    )
    print(f"Etherscan API Response (get_balances): {response.json}")
    assert response.status_code == 400
    assert "error" in response.json


def test_get_transactions(client):
    data = {"addresses": ["0xddBd2B932c763bA5b1b7AE3B362eac3e8d40121A"]}
    response = client.post(
        "/transactions", data=json.dumps(data), content_type="application/json"
    )
    print(f"Etherscan API Response (get_transactions): {response.json}")
    assert response.status_code == 200
    assert "transactions" in response.json


def test_get_transactions_for_two_accounts(client):
    data = {
        "addresses": [
            "0x9aa99c23f67c81701c772b106b4f83f6e858dd2e",
            "0xc5102fe9359fd9a28f877a67e36b0f050d81a3cc",
        ]
    }
    response = client.post(
        "/transactions", data=json.dumps(data), content_type="application/json"
    )
    print(f"Etherscan API Response (get_transactions): {response.json}")
    assert response.status_code == 200
    assert "transactions" in response.json


def test_get_transactions_invalid_input(client):
    data = {"invalid_key": "invalid_value"}
    response = client.post(
        "/transactions", data=json.dumps(data), content_type="application/json"
    )
    print(f"Etherscan API Response (get_transactions): {response.json}")
    assert response.status_code == 400
    assert "error" in response.json


def test_get_transactions_for_high_volume_address(client):
    data = {"addresses": ["0x9Fce8eB77Fb67660cB134F4EE4c82A48F415f812"]}
    response = client.post(
        "/transactions", data=json.dumps(data), content_type="application/json"
    )
    print(f"Etherscan API Response (get_transactions): {response.json}")
    assert response.status_code == 200
    assert "transactions" in response.json
    assert len(response.json["transactions"][0]["transactions"]) > 501