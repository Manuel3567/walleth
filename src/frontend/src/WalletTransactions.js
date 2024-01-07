// src/WalletTransactions.js
import React, { useState, useEffect } from 'react';
import { useAuth0 } from '@auth0/auth0-react';

const WalletTransactions = ({ walletAddress }) => {
    const [transactions, setTransactions] = useState([]);
    const { getAccessTokenSilently } = useAuth0();

    useEffect(() => {
        const fetchTransactions = async () => {
            try {
                const token = await getAccessTokenSilently({
                    //audience: 'api.app.portfolioeth.de', // Replace with your Auth0 Management API audience
                    //scope: 'openid email profile'
                });
                const headers = {
                    Authorization: `Bearer ${token}`,
                };
                const api = process.env.REACT_APP_API;
                const response = await fetch(api + '/data/', {
                    headers,
                });

                // Assuming the response is JSON
                const data = await response.json();

                // Use dummy transaction data (replace with actual data when available)
                const dummyTransactions = [
                    { id: 1, amount: 5.0, timestamp: '2023-01-01T12:00:00Z' },
                    { id: 2, amount: 3.5, timestamp: '2023-01-02T14:30:00Z' },
                    // Add more dummy transactions as needed
                ];

                setTransactions(dummyTransactions);
            } catch (error) {
                console.error('Error fetching transactions:', error);
            }
        };

        fetchTransactions();
    }, [getAccessTokenSilently, walletAddress]);

    return (
        <div>
            <h2>Wallet Transactions</h2>
            {transactions.length > 0 ? (
                <ul>
                    {transactions.map((transaction) => (
                        <li key={transaction.id}>
                            {transaction.amount} ETH - {transaction.timestamp}
                        </li>
                    ))}
                </ul>
            ) : (
                <p>No transactions found.</p>
            )}
        </div>
    );
};

export default WalletTransactions;
