
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


export function filterCustomerBalances(data) {
    const customers = data.customers
    const filteredCustomers = customers.filter(customer => {
        // Replace 'yourThreshold' with the actual threshold value
        return customer.balance || 0;
    });

    return filteredCustomers;


}