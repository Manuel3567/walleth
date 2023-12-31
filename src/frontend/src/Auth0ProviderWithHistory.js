import React from 'react';
import { Auth0Provider } from '@auth0/auth0-react';

//TODO: History currently not working
const Auth0ProviderWithHistory = ({ children }) => {
    const domain = process.env.REACT_APP_AUTH0_DOMAIN;
    const audience = process.env.REACT_APP_API;
    const clientId = process.env.REACT_APP_AUTH0_CLIENT_ID;
    const redirectUri = process.env.REACT_APP_AUTH0_REDIRECT_URI;;


    return (
        <Auth0Provider
            domain={domain}
            clientId={clientId}
            authorizationParams={{
                redirect_uri: redirectUri,
                audience: audience, // Replace with your Auth0 Management API audience
                scope: 'openid email profile read:sth'
            }}
        >
            {children}
        </Auth0Provider>
    );
};

export default Auth0ProviderWithHistory;
