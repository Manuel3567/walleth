import * as React from 'react';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import Title from './Title';
import { sumBalances } from '../../data/api';


function preventDefault(event) {
    event.preventDefault();
}


export default function Balance({ data }) {
    const totalBalance = sumBalances(data);

    return (
        <React.Fragment>
            <Title>Total Assets</Title>
            <Typography component="p" variant="h4">
                ETH {totalBalance}
            </Typography>
        </React.Fragment>
    );
}