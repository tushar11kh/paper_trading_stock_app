const { SubscriptionClient } = require('subscriptions-transport-ws');
const WebSocket = require('ws');
const gql = require('graphql-tag');

// Connect to your server's WebSocket endpoint
const client = new SubscriptionClient('ws://localhost:4000/graphql', {
  reconnect: true,
}, WebSocket);

// Define the subscription query
const PRICE_SUBSCRIPTION = gql`
  subscription($symbol: String!) {
    priceUpdate(symbol: $symbol) {
      symbol
      price
      name
    }
  }
`;

// Start the subscription
const subscription = client.request({
  query: PRICE_SUBSCRIPTION,
  variables: { symbol: 'ONGC' },
}).subscribe({
  next(data) {
    console.log('[📥 Update]', data);
  },
  error(err) {
    console.error('[❌ Error]', err);
  },
  complete() {
    console.log('[✅ Complete]');
  },
});

client.onConnected(() => {
    console.log('✅ WebSocket connected');
  });
  
  client.onDisconnected(() => {
    console.log('❌ WebSocket disconnected');
  });
  
