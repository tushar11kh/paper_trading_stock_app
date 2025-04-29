import { ApolloServer } from "apollo-server";
import dotenv from 'dotenv';
import {schema} from './graphql/schema';
import pool from './db/';
import redis from './db/redis';

dotenv.config();

export async function createServer() {
      
    try{

        const {rows} = await pool.query('SELECT NOW()');
        console.log('✅ Database connected at:',rows[0].now);

        const server = new ApolloServer({
            schema,
            context:({req})=>{return {req};}
        });

        return server;


    }catch(error){

        console.error('❌ Failed to connect to DB', error),
        process.exit(1);
    }

}
