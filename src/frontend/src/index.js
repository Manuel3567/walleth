import React from "react";
import ReactDOM from "react-dom/client";
import "./index.css";
import App from "./App";
import Error from "./scenes/errors/Error";
import { createBrowserRouter, createHashRouter, RouterProvider } from "react-router-dom";
import Portfolio from './scenes/portfolio/Portfolio';
import Company from './scenes/company/Company';
import Premium from './scenes/premium/Premium';
import Profile from './scenes/profile/Profile';
import Customers from './scenes/customers/Customers';
import AuthProvider from './Auth0Provider';


const router = createHashRouter([
    {
        path: "/",
        element: <App />,
        errorElement: <Error />,
        children: [
            {
                path: "portfolio",
                element: <Portfolio />,
            },
            {
                path: "company",
                element: <Company />,
            },
            {
                path: "profile",
                element: <Profile />,
            },
            {
                path: "trades",
                element: <Premium />,
            },
            {
                path: "reports",
                element: <Premium />,
            },
            {
                path: "customers",
                element: <Customers />,
            },
        ]
    },

]);

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(
    <React.StrictMode>
        <AuthProvider>
            <RouterProvider router={router} />
        </AuthProvider>
    </React.StrictMode>
);