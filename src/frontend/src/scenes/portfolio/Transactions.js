import * as React from 'react';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Title from './Title';
import { filterTransactions } from '../../data/api';

function hash(s) {
    for (var i = 0, h = 9; i < s.length;)h = Math.imul(h ^ s.charCodeAt(i++), 9 ** 9); return h ^ h >>> 9
}

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
                        <TableRow key={hash(JSON.stringify(t))}>
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