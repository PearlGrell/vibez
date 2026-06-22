const http = require('http');

http.get('http://localhost:3000/api/search?q=something%20stupid', (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('STATUS CODE:', res.statusCode);
    console.log('HEADERS:', res.headers);
    try {
      console.log('RESPONSE BODY:', JSON.stringify(JSON.parse(data), null, 2));
    } catch (e) {
      console.log('RAW RESPONSE BODY:', data);
    }
  });
}).on('error', (err) => {
  console.error('Request Error:', err.message);
});
