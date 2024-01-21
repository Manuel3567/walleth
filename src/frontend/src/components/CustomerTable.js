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


function hash(s) {
    for (var i = 0, h = 9; i < s.length;)h = Math.imul(h ^ s.charCodeAt(i++), 9 ** 9); return h ^ h >>> 9
}

function CustomerTable({ data, setData }) {
    window.history.replaceState({}, document.title);
    const [customers, setCustomers] = useState(data.customers);
    const [editMode, setEditMode] = useState(false);
    const [selectedCustomer, setSelectedCustomer] = useState(null);
    const [oldCustomers, setOldCustomers] = useState(JSON.parse(JSON.stringify(data.customers)));
    const [newCustomer, setNewCustomer] = useState(null);
    const [newWalletCustomers, setNewWalletCustomers] = useState([]);
    const [newWallet, setNewWallet] = useState(null);
    const [newCustomers, setNewCustomers] = useState([]);
    const [removeCustomers, setRemoveCustomers] = useState([]);

    const { getAccessTokenSilently } = useAuth0();

    const handleEditClick = () => {
        if (editMode) {
            // revert changes
            setCustomers(oldCustomers);
        } else {
            // start editing and save current customers
            setOldCustomers(JSON.parse(JSON.stringify(customers)));
        }
        setEditMode(!editMode);
        setNewCustomer(null);
        setNewWallet(null);
        setNewWalletCustomers([]);
        setNewCustomers([]);
        setRemoveCustomers([]);
    };

    const handleRowClick = (customerName) => {
        setSelectedCustomer(
            selectedCustomer === customerName ? null : customerName
        );
    };

    const handleAddWallet = (customerIndex) => {
        let customer = customers[customerIndex];
        if (newWallet && newWallet.address.trim() !== '') {
            const isExistingWallet = customer.wallets.some((wallet) => wallet.address === newWallet.address);
            if (!isExistingWallet) {
                delete newWallet.customer;
                customer.wallets.push(newWallet);
                setNewWalletCustomers([...newWalletCustomers, customer]);
                //setCustomers([...customers.splice(customerIndex, 0, customer)]);
            } else {
                console.log("wallet already exists");
            }
        } else {
            console.log("error adding wallet");
        }
        setNewWallet(null);
    }

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
            setSelectedCustomer(null);
            setNewCustomer({
                name: '',
                email: '',
                phone: '',
                address: '',
                wallets: [],
            });
        }
    };


    const handleDeleteWallet = (customerIndex, walletIndex, wallet) => {
        // remove from customers
        console.log("Deleting wallet...");
        console.log(wallet);
        console.log(customerIndex);
        let customer = customers[customerIndex];
        console.log("Found customer...");
        console.log(customer);
        customer.wallets.splice(walletIndex, 1);
        console.log("Customer wallets...");
        console.log(customer.wallets);

        setCustomers([...customers]);
        // remove from newWalletCostumers
        setNewWalletCustomers(newWalletCustomers.filter(c => c.name !== customer.name && !c.wallets.includes({ address: wallet.address })));
        //schedule for deletion
        setRemoveCustomers([...removeCustomers, { name: customer.name, wallets: [{ address: wallet.address }] }]);
    };

    const handleDeleteCustomer = (customerName) => {
        setCustomers((prevCustomers) =>
            prevCustomers.filter((customer) => customer.name !== customerName)
        );
        setRemoveCustomers([...removeCustomers, { name: customerName }])
    };

    const handleCommit = async () => {
        const accessToken = await getAccessTokenSilently();

        //new wallet customers
        let payload = {
            customers: newWalletCustomers,
        };

        try {
            const response = fetch(`${process.env.REACT_APP_API}/data/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${accessToken}`,
                },
                body: JSON.stringify(payload),
            });
            if (!response.ok) {
                console.log(`failed to create customers: ${payload}`);
            }
        } catch (error) {
            console.error('Error creating customers:', error.message);
        }

        //create customers
        payload = {
            customers: newCustomers,
        };

        try {
            const response = fetch(`${process.env.REACT_APP_API}/data/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${accessToken}`,
                },
                body: JSON.stringify(payload),
            });
            if (!response.ok) {
                console.log(`failed to create customers: ${payload}`);
            }
        } catch (error) {
            console.error('Error creating customers:', error.message);
        }
        // delete customers
        try {
            payload = {
                customers: removeCustomers,
            };
            const response = fetch(`${process.env.REACT_APP_API}/data/`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${accessToken}`,
                },
                body: JSON.stringify(payload),
            });
            if (!response.ok) {
                console.log(`failed to delete ${payload}`);
            }
        } catch (error) {
            console.error('Error deleting customers:', error.message);
        }


        setData({ customers: [...customers.filter((c) => !removeCustomers.includes(c.name)), ...newCustomers] });
        setSelectedCustomer(null);
        setOldCustomers(JSON.parse(JSON.stringify(customers)));
        setNewCustomer(null);
        setNewCustomers([]);
        setRemoveCustomers([]);
        setEditMode(!editMode);
        setNewWalletCustomers([]);
        setNewWallet(null);
    };


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
                        {customers.map((customer, customerIndex) => (
                            <React.Fragment key={customer.name}>
                                <TableRow
                                    hover
                                    onClick={() => handleRowClick(customer.name)}
                                >
                                    <TableCell>{customer.name}</TableCell>
                                    <TableCell>{customer.email}</TableCell>
                                    <TableCell>{customer.phone}</TableCell>
                                    <TableCell>{customer.address}</TableCell>
                                    {editMode && <TableCell>
                                        <IconButton
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                handleDeleteCustomer(customer.name);
                                            }}
                                        >
                                            <DeleteIcon />
                                        </IconButton>
                                    </TableCell>}
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
                                                <TableRow>
                                                    <TableCell>Address</TableCell>
                                                    <TableCell></TableCell>
                                                </TableRow>
                                                {customer.wallets.map((wallet, walletIndex) => (
                                                    <React.Fragment key={customer.name.concat(wallet.address)}>
                                                        <TableRow hover onClick={() => handleRowClick(customer.name)}>
                                                            <TableCell>{wallet.address}</TableCell>
                                                            {editMode && <>
                                                                <TableCell>
                                                                    <IconButton
                                                                        onClick={(e) => {
                                                                            e.stopPropagation();
                                                                            handleDeleteWallet(customerIndex, walletIndex, wallet);
                                                                        }}
                                                                    >
                                                                        <DeleteIcon />
                                                                    </IconButton>
                                                                </TableCell>
                                                            </>}
                                                        </TableRow>
                                                    </React.Fragment>
                                                ))}
                                                {editMode && newWallet !== null && newWallet.customer === customer.name &&
                                                    <TableRow>
                                                        <TableCell>
                                                            <TextField
                                                                value={newWallet.address}
                                                                onChange={(e) => setNewWallet({ ...newWallet, address: e.target.value })}
                                                            />
                                                        </TableCell>
                                                        <TableCell>
                                                            {/* Button to add newWallet or save changes */}
                                                            <IconButton onClick={(e) => setNewWallet(null)}>
                                                                <DeleteIcon />
                                                            </IconButton>
                                                        </TableCell>
                                                        <TableCell>
                                                            {/* Button to add newWallet or save changes */}
                                                            <IconButton onClick={(e) => handleAddWallet(customerIndex)}>
                                                                <CheckIcon />
                                                            </IconButton>
                                                        </TableCell>
                                                    </TableRow>}

                                                {editMode && (
                                                    <IconButton
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            setNewWallet({ 'address': '', 'customer': customer.name });
                                                        }}
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
                                    <IconButton onClick={(e) => setNewCustomer(null)}>
                                        <DeleteIcon />
                                    </IconButton>
                                </TableCell>
                                <TableCell>
                                    {/* Button to add newCustomer or save changes */}
                                    <IconButton onClick={handleAddCustomer}>
                                        <CheckIcon />
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
                    <Button onClick={handleCommit} startIcon={<CheckIcon />}>
                        Save Changes
                    </Button>
                </Box>
            )}
        </Box>
    );
}

export default CustomerTable;
