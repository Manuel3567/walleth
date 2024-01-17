import { React, useState, useEffect } from 'react'
import { Outlet } from "react-router-dom";
import Topbar from './scenes/global/Topbar';
import HomePage from './scenes/global/HomePage';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';
import { useAuth0 } from "@auth0/auth0-react";
import Error from "./scenes/errors/Error";
import { HashRouter, Routes, Route } from "react-router-dom";
import Portfolio from './scenes/portfolio/Portfolio';
import Company from './scenes/company/Company';
import Premium from './scenes/premium/Premium';
import Profile from './scenes/profile/Profile';
import Customers from './scenes/customers/Customers';


//import Topbar from './scenes/global/Topbar'

function AuthenticatedApp() {
    const [data, setData] = useState({ 'customers': [] });

    const { getAccessTokenSilently } = useAuth0();

    useEffect(() => {
        let isMounted = true;

        const getData = async () => {
            if (!isMounted) {
                return;
            }
            const accessToken = await getAccessTokenSilently();
            const response = await fetch(
                process.env.REACT_APP_API + '/data/', {
                'headers': {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
            );

            if (response.ok) {
                let new_data = await response.json();
                setData(new_data);
            }

        };

        getData();

        return () => {
            isMounted = false;
        };
    }, [getAccessTokenSilently, setData]);

    return (
        <Box sx={{ display: 'flex' }}>
            <CssBaseline />
            <Topbar />
            <Outlet context={[data, setData]} />
        </Box>
    )
}

export default function App() {
    const { isAuthenticated } = useAuth0();
    if (isAuthenticated) {
        return (
            <HashRouter>
                <Routes>
                    <Route path='/' element={<AuthenticatedApp />}>
                        <Route path='/portfolio' element={<Portfolio />} />
                        <Route path='/company' element={<Company />} />
                        <Route path='/customers' element={<Customers />} />
                        <Route path='/profile' element={<Profile />} />
                        <Route path='/trades' element={<Premium />} />
                        <Route path='/reports' element={<Premium />} />
                    </Route>
                </Routes>
            </HashRouter>
        );
    } else {
        return (
            <Box sx={{ display: 'flex' }}>
                <CssBaseline />
                <HomePage />
            </Box>
        );

    }
}