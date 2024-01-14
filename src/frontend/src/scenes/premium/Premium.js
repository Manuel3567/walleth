import * as React from 'react';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Container from '@mui/material/Container';
import Grid from '@mui/material/Grid';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Copyright from '../../components/Copyright';

export default function Premium() {
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
                <Grid container spacing={3} justifyContent="center" alignItems="center">
                    <Grid item xs={12} md={8} lg={9}>
                        <Paper
                            sx={{
                                p: 4,
                                display: 'flex',
                                flexDirection: 'column',
                                height: 240,
                                textAlign: 'center',
                                borderRadius: '8px', // Rounded corners for a softer look
                            }}
                        >
                            <Typography variant="h4" sx={{ fontFamily: 'Roboto', fontWeight: 'bold', color: '#555', lineHeight: '1.6' }}>
                                Contact your sales representative to enable
                            </Typography>
                        </Paper>
                    </Grid>
                </Grid>
                <Copyright sx={{ pt: 4 }} />
            </Container>
        </Box>
    );
}
