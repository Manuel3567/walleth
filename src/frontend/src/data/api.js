
export function sumBalances(data) {
    let totalBalance = 0;

    data.customers.forEach(customer => {
        customer.wallets.forEach(wallet => {
            if (wallet.balance) {
                totalBalance += parseFloat(wallet.balance / (10 ** 16));
            }
        });
    });

    return totalBalance;
}

export function filterTransactions(data) {
    let res = [];
    let cs = data.customers;
    cs.forEach(c => { c.wallets.forEach(w => { res.push(...w.transactions) }) });
    return res;
}

export function filterCustomerBalances(data) {
    const customers = data.customers
    const filteredCustomers = customers.filter(customer => {
        // Replace 'yourThreshold' with the actual threshold value
        return customer.balance || 0;
    });

    return filteredCustomers;


}