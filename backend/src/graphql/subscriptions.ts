// backend/src/graphql/subscriptions.ts
import { execute, subscribe } from 'graphql';
import { SubscriptionServer } from 'subscriptions-transport-ws';
import { schema } from './schema';

export const createSubscriptionServer = (server: any) => {
  return SubscriptionServer.create(
    {
      schema,
      execute,
      subscribe,
      onConnect: () => {
        console.log('[WS] New connection');
        return true;
      },
      onDisconnect: () => console.log('[WS] Disconnected'),
    },
    {
      server,
      path: '/graphql',
    }
  );
};