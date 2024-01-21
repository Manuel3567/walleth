import { React, useState, useEffect } from 'react'
import { Outlet, useLocation } from "react-router-dom";
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
    const location = useLocation()
    const [data, setData] = useState({ 'customers': [] });

    const { getAccessTokenSilently } = useAuth0();

    const getData = async () => {
        const accessToken = await getAccessTokenSilently();
        const response = await fetch(
            process.env.REACT_APP_API + '/data/', {
            'headers': {
                'Authorization': `Bearer ${accessToken}`
            }
        }
        );

        if (response.ok) {
            const new_data = await response.json();
            setData(new_data);
        }
    };

    const handleUpdateToData = async (event) => {
        await getData();
    };

    useEffect(() => {
        let isMounted = true;

        getData();
        //window.addEventListener('hashchange', handleUpdateToData);
        //browser.webNavigation.onReferenceFragmentUpdated.addListener(handleUpdateToData);

        return () => {
            isMounted = false;
            //window.removeEventListener('hashchange', handleUpdateToData);
            //browser.webNavigation.onReferenceFragmentUpdated.removeListener(handleUpdateToData);
        };
    }, [getAccessTokenSilently, location, setData]);


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