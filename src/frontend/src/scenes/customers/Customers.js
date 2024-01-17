import * as React from 'react';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Container from '@mui/material/Container';
import Grid from '@mui/material/Grid';
import Paper from '@mui/material/Paper';
import Copyright from '../../components/Copyright';
import CustomerTable from '../../components/CustomerTable';
import { useOutletContext } from 'react-router-dom';


export default function Customers() {
    const [data, setData] = useOutletContext();

    return (
        <Box
            sx={{
                backgroundColor: (theme) =>
                    theme.palette.mode === 'light'
                        ? theme.palette.grey[100]
                        : theme.palette.grey[900],
                flexGrow: 1,
                height: '100vh',
                overflow: 'auto',
            }}
        >
            <Toolbar />
            <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
                <Grid item xs={12} md={12} lg={12}>
                    <CustomerTable data={data} setData={setData} />
                </Grid>
                <Copyright sx={{ pt: 4 }} />
            </Container>
        </Box>
    );
}