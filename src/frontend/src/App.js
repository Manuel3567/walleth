import { Outlet } from "react-router-dom";
import Topbar from './scenes/global/Topbar';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';

//import Topbar from './scenes/global/Topbar'

const defaultTheme = createTheme();
export default function App() {

    return (
        <ThemeProvider theme={defaultTheme}>
            <Box sx={{ display: 'flex' }}>
                <CssBaseline />
                <Topbar />
                <Outlet />
            </Box>
        </ThemeProvider>
    );
}