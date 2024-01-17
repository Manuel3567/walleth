import * as React from 'react';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import Title from './Title';
import { sumBalances } from '../../data/api';


function preventDefault(event) {
    event.preventDefault();
}


export default function Balance({ customers }) {
    const totalBalance = sumBalances(customers);

    return (
        <React.Fragment>
            <Title>Balance</Title>
            <Typography component="p" variant="h4">
                ETH {totalBalance}
            </Typography>
            <div>
                <Link color="primary" href="#" onClick={preventDefault}>
                    View balance
                </Link>
            </div>
        </React.Fragment>
    );
}