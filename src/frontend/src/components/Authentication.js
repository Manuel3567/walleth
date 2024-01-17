import { useAuth0 } from "@auth0/auth0-react";
import React from "react";

export const LoginButton = () => {
    const { loginWithRedirect } = useAuth0();

    const handleLogin = async () => {
        await loginWithRedirect({
            appState: {
                returnTo: "/",
            },
        });
    };

    return (
        <button className="button__login" onClick={handleLogin}>
            Log In
        </button>
    );
};


export const SignupButton = () => {
    const { loginWithRedirect } = useAuth0();

    const handleSignUp = async () => {
        await loginWithRedirect({
            appState: {
                returnTo: "/",
            },
            authorizationParams: {
                screen_hint: "signup",
            },
        });
    };

    return (
        <button className="button__sign-up" onClick={handleSignUp}>
            Sign Up
        </button>
    );
};


export const LogoutButton = () => {
    const { logout } = useAuth0();

    const handleLogout = () => {
        logout({
            logoutParams: {
                returnTo: window.location.origin,
            },
        });
    };

    return (
        <button className="button__logout" onClick={handleLogout}>
            Log Out
        </button>
    );
};