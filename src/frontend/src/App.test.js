import { render, screen } from '@testing-library/react';
import App from './App';
import Balance from './scenes/portfolio/Balance';
import Transactions from './scenes/portfolio/Transactions';
import { getCustomers } from './data/mockCustomers';
import { sumBalances, filterCustomerBalances } from './data/api';

//test('renders learn react link', () => {
//    render(<App />);
//    const textElement = screen.getByText("Portfolioeth");
//    expect(textElement).toBeInTheDocument();
//});
test('sum balances correctly', () => {
    let data = {
        "customers": [
            {
                "name": "Abc Customer",
                "wallets": [
                ]
            },
            {
                "name": "Def Customer",
                "wallets": [

                ]
            },
            {
                "name": "Ghi Customer",
                "wallets": [
                    {
                        "balance": "2277654394317223",
                        "transactions": []
                    }
                ]
            }
        ]
    }
    const total = sumBalances(data);
    expect(total).toBeGreaterThan(0);
});

test('renders Budget', () => {
    let data = {
        "customers": [
            {
                "name": "Abc Customer",
                "wallets": [
                ]
            },
            {
                "name": "Def Customer",
                "wallets": [

                ]
            },
            {
                "name": "Ghi Customer",
                "wallets": [
                    {
                        "balance": "2277654394317223",
                        "transactions": []
                    }
                ]
            }
        ]
    }
    render(<Balance data={data} />);
    const textElement = screen.getByText("ETH 0");
    expect(textElement).toBeInTheDocument();
});

test('renders Transactions', () => {
    const data = getCustomers();
    render(<Transactions data={data} />);
    const textElement = screen.getByText("Smart Contract");
    expect(textElement).toBeInTheDocument();

});