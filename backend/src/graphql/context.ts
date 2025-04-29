// backend/src/graphql/context.ts
import { Pool } from 'pg';
import type { Redis } from 'ioredis';
import { Request } from 'express';
import pool from '../db';
import redis from '../db/redis';


export interface Context {
  req?: Request;
  pool: Pool;
  redis: Redis;
}

export async function createContext(initialContext?: { req?: Request }): Promise<Context> {
  return {
    ...initialContext,
    pool,
    redis,
  };
}