import React, { useState, useEffect } from 'react';
import {
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper,
    IconButton,
    TextField,
    Button,
    Collapse,
    Box,
    Toolbar,
    Typography,
    FormControlLabel,
    Switch,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import CheckIcon from '@mui/icons-material/Check';
import CloseIcon from '@mui/icons-material/Close';
import DeleteIcon from '@mui/icons-material/Delete';
import { useAuth0 } from "@auth0/auth0-react";

function CustomerTable({ data, setData }) {
    const [customers, setCustomers] = useState([...data.customers]);
    const [editMode, setEditMode] = useState(false);
    const [selectedCustomer, setSelectedCustomer] = useState(null);
    const [oldCustomers, setOldCustomers] = useState([...data.customers]);
    const [newCustomer, setNewCustomer] = useState(null);
    const [newCustomers, setNewCustomers] = useState([]);

    const { getAccessTokenSilently } = useAuth0();

    const handleEditClick = () => {
        setEditMode(!editMode);
        setSelectedCustomer(null);
    };

    const handleRowClick = (customerName) => {
        setSelectedCustomer(
            selectedCustomer === customerName ? null : customerName
        );
    };

    const handleAddCustomer = () => {
        // If newCustomer is not null, add it to customers
        if (newCustomer && newCustomer.name.trim() !== '') {
            // Check if a customer with the same name already exists
            const isExistingCustomer = customers.some((customer) => customer.name === newCustomer.name);

            if (!isExistingCustomer) {
                // Add the new customer to customers
                setCustomers([...customers, newCustomer]);

                // Add the new customer to newCustomers
                setNewCustomers([...newCustomers, newCustomer]);

                // Reset newCustomer to null
                setNewCustomer(null);
            } else {
                // Handle case where a customer with the same name already exists
                console.error('Customer with the same name already exists.');
                // You might want to show an error message to the user or take other actions.
            }
        } else {
            // If newCustomer is null or has an empty name, create a new empty customer
            setNewCustomer({
                name: '',
                email: '',
                phone: '',
                address: '',
                wallets: [],
            });
        }
    };


    const handleDeleteWallet = (customerId, walletIndex) => {
        setCustomers((prevCustomers) => {
            const updatedCustomers = [...prevCustomers];
            const customerIndex = updatedCustomers.findIndex(
                (customer) => customer.id === customerId
            );
            updatedCustomers[customerIndex].wallets.splice(
                walletIndex,
                1
            );
            return updatedCustomers;
        });
        setNewCustomers((prevNewCustomers) => {
            const updatedNewCustomers = [...prevNewCustomers];
            const newCustomerIndex = updatedNewCustomers.findIndex(
                (customer) => customer.id === customerId
            );
            updatedNewCustomers[newCustomerIndex].wallets.splice(walletIndex, 1);
            return updatedNewCustomers;
        });
    };

    const handleDeleteCustomer = (customerId) => {
        setCustomers((prevCustomers) =>
            prevCustomers.filter((customer) => customer.id !== customerId)
        );
    };

    const handleCheckmarkClick = () => {
        // Assuming your API endpoint is at '/api/customers'
        const apiUrl = '/api/customers';

        customers.forEach(async (customer) => {
            if (customer.id < 0) {
                // New customer, send POST request
                const response = await fetch(apiUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(customer),
                });

                if (!response.ok) {
                    console.error('Failed to add customer:', response.statusText);
                }
            } else {
                // Existing customer, send DELETE request for wallets and customer
                customer.wallets.forEach(async (wallet, index) => {
                    const walletResponse = await fetch(
                        `${apiUrl}/${customer.id}/wallets/${index}`,
                        {
                            method: 'DELETE',
                        }
                    );

                    if (!walletResponse.ok) {
                        console.error(
                            'Failed to delete wallet:',
                            walletResponse.statusText
                        );
                    }
                });

                const customerResponse = await fetch(
                    `${apiUrl}/${customer.id}`,
                    {
                        method: 'DELETE',
                    }
                );

                if (!customerResponse.ok) {
                    console.error(
                        'Failed to delete customer:',
                        customerResponse.statusText
                    );
                }
            }
        });
    };


    const deleteCustomers = async () => {
        const payload = {
            //customers: selected.map((name) => ({ name })),
        };

        try {
            const accessToken = await getAccessTokenSilently();
            const response = await fetch(`${process.env.REACT_APP_API}/data/`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${accessToken}`,
                },
                body: JSON.stringify(payload),
            });

            if (response.ok) {
                //const updatedRows = rows.filter((row) => !selected.includes(row.name));
                //const updatedData = {
                //    ...data,
                //    customers: data.customers.filter((customer) => !selected.includes(customer.name)),
                //};
                //setSelected([]);
                //setData(updatedData);
                //setRows(updatedRows);
            } else {
                console.error('Failed to delete customers:', response.statusText);
            }
        } catch (error) {
            console.error('Error deleting customers:', error.message);
        }
    };
    console.log(data);

    return (
        <Box>
            <Toolbar>
                <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                    Customers
                </Typography>
                <IconButton onClick={handleEditClick}>
                    {editMode ? <CloseIcon /> : <EditIcon />}
                </IconButton>
            </Toolbar>
            <TableContainer component={Paper}>
                <Table>
                    <TableHead>
                        <TableRow>
                            <TableCell>Name</TableCell>
                            <TableCell>Email</TableCell>
                            <TableCell>Phone</TableCell>
                            <TableCell>Address</TableCell>
                            <TableCell></TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {customers.map((customer) => (
                            <React.Fragment key={customer.name}>
                                <TableRow
                                    hover
                                    onClick={() => handleRowClick(customer.name)}
                                >
                                    <TableCell>{customer.name}</TableCell>
                                    <TableCell>{customer.email}</TableCell>
                                    <TableCell>{customer.phone}</TableCell>
                                    <TableCell>{customer.address}</TableCell>
                                    <TableCell>
                                        <IconButton
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                handleDeleteCustomer(customer.name);
                                            }}
                                        >
                                            <DeleteIcon />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                                <TableRow>
                                    <TableCell colSpan={7}>
                                        <Collapse
                                            in={selectedCustomer === customer.name}
                                        >
                                            <Box margin={1}>
                                                <Typography gutterBottom>
                                                    Wallets
                                                </Typography>
                                                {editMode && (
                                                    <IconButton
                                                        onClick={() =>
                                                            setCustomers((prevCustomers) => {
                                                                const updatedCustomers = [
                                                                    ...prevCustomers,
                                                                ];
                                                                const customerIndex =
                                                                    updatedCustomers.findIndex(
                                                                        (c) => c.name === customer.name
                                                                    );
                                                                updatedCustomers[
                                                                    customerIndex
                                                                ].wallets.push('');
                                                                return updatedCustomers;
                                                            })
                                                        }
                                                    >
                                                        <AddIcon />
                                                    </IconButton>
                                                )}
                                            </Box>
                                        </Collapse>
                                    </TableCell>
                                </TableRow>
                            </React.Fragment>
                        ))}
                        {editMode && newCustomer !== null && (
                            <TableRow>
                                <TableCell>
                                    <TextField
                                        value={newCustomer.name}
                                        onChange={(e) => setNewCustomer({ ...newCustomer, name: e.target.value })}
                                    />
                                </TableCell>
                                <TableCell>
                                    <TextField
                                        value={newCustomer.email}
                                        onChange={(e) => setNewCustomer({ ...newCustomer, email: e.target.value })}
                                    />
                                </TableCell>
                                <TableCell>
                                    <TextField
                                        value={newCustomer.phone}
                                        onChange={(e) => setNewCustomer({ ...newCustomer, phone: e.target.value })}
                                    />
                                </TableCell>
                                <TableCell>
                                    <TextField
                                        value={newCustomer.address}
                                        onChange={(e) => setNewCustomer({ ...newCustomer, address: e.target.value })}
                                    />
                                </TableCell>
                                <TableCell>
                                    {/* Button to add newCustomer or save changes */}
                                    <IconButton onClick={handleAddCustomer}>
                                        <AddIcon />
                                    </IconButton>
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
            {editMode && (
                <Box mt={2}>
                    <Button onClick={handleAddCustomer} startIcon={<AddIcon />}>
                        Add Customer
                    </Button>
                    <Button onClick={handleCheckmarkClick} startIcon={<CheckIcon />}>
                        {editMode ? 'Save Changes' : 'Edit Mode'}
                    </Button>
                </Box>
            )}
        </Box>
    );
}

export default CustomerTable;
