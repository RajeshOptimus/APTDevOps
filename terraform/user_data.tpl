#!/bin/bash
# Install Node.js app, run on port ${app_port}

# Update and install dependencies
yum update -y
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git

# Create app directory
mkdir -p /opt/devops-app
cat > /opt/devops-app/index.js <<'EOF'
const http = require('http');
const port = process.env.APP_PORT || ${app_port};
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
EOF

# Create systemd service
cat > /etc/systemd/system/devops-app.service <<'EOF'
[Unit]
Description=DevOps assignment Node app
After=network.target

[Service]
Environment=APP_PORT=${app_port}
ExecStart=/usr/bin/node /opt/devops-app/index.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable devops-app
systemctl start devops-app

# install and configure cloudwatch logs agent optional

