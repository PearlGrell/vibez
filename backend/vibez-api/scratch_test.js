const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

const PROTO_PATH = path.join(__dirname, '..', 'protos', 'search.proto');

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});

const searchProto = grpc.loadPackageDefinition(packageDefinition).search;

function main() {
  const client = new searchProto.Search('localhost:50051', grpc.credentials.createInsecure());
  client.Search({ query: 'something stupid', filter: 'ALL' }, (err, response) => {
    if (err) {
      console.error('Error received:', err);
    } else {
      console.log('Response received:', JSON.stringify(response, null, 2));
    }
  });
}

main();
