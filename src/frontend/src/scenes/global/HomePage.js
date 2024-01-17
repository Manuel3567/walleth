import { Box } from "@mui/material";
import { LoginButton, SignupButton } from "../../components/Authentication";
export default function HomePage() {
    return (
        <Box sx={{ display: 'flex' }} >
            <LoginButton/>
            <SignupButton/>

        </Box>
    );
}