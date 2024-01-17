import { React, useState, useEffect } from 'react'
import { Outlet } from "react-router-dom";
import Topbar from './scenes/global/Topbar';
import HomePage from './scenes/global/HomePage';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';
import { useAuth0 } from "@auth0/auth0-react";


//import Topbar from './scenes/global/Topbar'

function AuthenticatedApp() {
    const [customers, setCustomers] = useState({ 'customers': [] });

    const { getAccessTokenSilently } = useAuth0();

    useEffect(() => {
        let isMounted = true;

        const getData = async () => {
            if (!isMounted) {
                return;
            }
            const accessToken = await getAccessTokenSilently();
            const { data, error } = await fetch(
                process.env.REACT_APP_API + '/data/', {
                'headers': {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
            );

            if (data) {
                setCustomers(data);
            }

            if (error) {
                console.log("Error fetching data");
                console.log(error);
            }
        };

        getData();

        return () => {
            isMounted = false;
        };
    }, [getAccessTokenSilently]);
    return (
        <Box sx={{ display: 'flex' }}>
            <CssBaseline />
            <Topbar />
            <Outlet context={[customers, setCustomers]} />
        </Box>
    )
}

const defaultTheme = createTheme();
export default function App() {
    const { isAuthenticated } = useAuth0();
    if (isAuthenticated) {
        return (
            <ThemeProvider theme={defaultTheme}>
                <AuthenticatedApp />
            </ThemeProvider>
        );
    } else {
        return (
            <ThemeProvider theme={defaultTheme}>
                <Box sx={{ display: 'flex' }}>
                    <CssBaseline />
                    <HomePage />
                </Box>
            </ThemeProvider>
        );

    }
}