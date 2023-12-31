// src/App.js
import React from 'react';
import { useAuth0 } from '@auth0/auth0-react';
import WalletBalance from './WalletBalance';
import WalletTransactions from './WalletTransactions';

const App = () => {
  const { loginWithRedirect, logout, user, isAuthenticated } = useAuth0();
  console.log('Is Authenticated:', isAuthenticated);
  console.log('User', user);
  return (
    <div>
      <header>
        <h1>Ethereum Wallet Tracker</h1>
        {isAuthenticated ? (
          <>
            <p>Hello, {user.name}!</p>
            <button onClick={() => logout()}>Logout</button>
          </>
        ) : (
          <button onClick={() => loginWithRedirect()}>Login</button>
        )}
      </header>

      {isAuthenticated && (
        <main>
          <WalletBalance walletAddress="YOUR_WALLET_ADDRESS" />
          <WalletTransactions walletAddress="YOUR_WALLET_ADDRESS" />
        </main>
      )}
    </div>
  );
};

export default App;
