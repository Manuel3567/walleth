// src/WalletBalance.js
import React, { useState, useEffect } from 'react';
import { useAuth0 } from '@auth0/auth0-react';

const WalletBalance = ({ walletAddress }) => {
    const [balance, setBalance] = useState(null);
    const { getAccessTokenSilently } = useAuth0();

    useEffect(() => {
        const fetchBalance = async () => {
            try {
                const token = await getAccessTokenSilently({
                    //audience: 'api.app.portfolioeth.de', // Replace with your Auth0 Management API audience
                    //scope: 'openid email profile'
                });
                const headers = {
                    Authorization: `Bearer ${token}`,
                };
                console.log(token);

                // Simulate fetching balance from localhost:80/headers
                const api = process.env.REACT_APP_API;
                const response = await fetch(api + '/data/', {
                    headers,
                });

                // Assuming the response is JSON
                const data = await response.json();
                console.log(data);

                // Use dummy balance data (replace with actual data when available)
                const dummyBalance = 10.5; // Example dummy balance in ETH
                setBalance(dummyBalance);
            } catch (error) {
                console.error('Error fetching balance:', error);
            }
        };

        fetchBalance();
    }, [getAccessTokenSilently, walletAddress]);

    return (
        <div>
            <h2>Wallet Balance</h2>
            {balance !== null ? (
                <p>Your wallet balance is: {balance} ETH</p>
            ) : (
                <p>Loading balance...</p>
            )}
        </div>
    );
};

export default WalletBalance;
