import { setupServer } from 'msw/node';
import { rest } from 'msw';

import { getCustomers } from '../data/mockCustomers'
const server = setupServer(
    // Define your request handlers here
    rest.get(process.env.REACT_APP_API + '/data', (req, res, ctx) => {
        // Return a mocked response
        return res(ctx.json(getCustomers()));
    }),
);

export { server };
