import { createServer } from './app';

async function start() {
    
    const server = await createServer();

    server.listen({port:4000}).then(({url})=>{
        console.log(`🚀 Server ready at ${url}`);
    });
}

start();