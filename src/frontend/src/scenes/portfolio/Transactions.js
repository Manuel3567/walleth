import * as React from 'react';
import Link from '@mui/material/Link';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Title from './Title';
import { filterTransactions } from '../../data/api';


function preventDefault(event) {
    event.preventDefault();
}

export default function Transactions({ data }) {
    const ts = filterTransactions(data);
    return (
        <React.Fragment>
            <Title>Recent Transactions</Title>
            <Table size="small">
                <TableHead>
                    <TableRow>
                        <TableCell>Date</TableCell>
                        <TableCell>Type</TableCell>
                        <TableCell>From</TableCell>
                        <TableCell>To</TableCell>
                        <TableCell>Amount</TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {ts.map((t) => (
                        <TableRow key={t.hash}>
                            <TableCell>{(new Date(parseInt(t.timeStamp) * 1000)).toLocaleString('de')}</TableCell>
                            <TableCell>{t.input ? "Smart Contract" : "Transfer"}</TableCell>
                            <TableCell>{t.from_address}</TableCell>
                            <TableCell>{t.to_address}</TableCell>
                            <TableCell align="left">{`${t.value / 10 ** 18} ETH`}</TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>
        </React.Fragment>
    );
}