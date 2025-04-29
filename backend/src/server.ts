import { createServer } from './app';
import { startStockPriceFetcher } from './services/stockFetcherService';

async function start() {
    
    const server = await createServer();

    server.listen({port:4000}).then(({url})=>{
        console.log(`🚀 Server ready at ${url}`);
    });
}

start();
startStockPriceFetcher();