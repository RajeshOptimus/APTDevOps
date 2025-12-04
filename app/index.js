const http = require('http');
const port = process.env.APP_PORT || 8080;
const server = http.createServer((req, res) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    return res.end('ok');
  }
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from DevOps assignment');
});
server.listen(port, () => console.log(`Listening on ${port}`));
