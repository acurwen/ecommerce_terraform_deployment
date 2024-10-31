#!/bin/bash

# public_key for Codon
pkey="ssh-rsaAAAAB3NzaC1yc2EAAAADAQABAAABgQDSkMc19m28614Rb3sGEXQUN+hk4xGiufU9NYbVXWGVrF1bq6dEnAD/VtwM6kDc8DnmYD7GJQVvXlDzvlWxdpBaJEzKziJ+PPzNVMPgPhd01cBWPv82+/Wu6MNKWZmi74TpgV3kktvfBecMl+jpSUMnwApdA8Tgy8eB0qELElFBu6cRz+f6Bo06GURXP6eAUbxjteaq3Jy8mV25AMnIrNziSyQ7JOUJ/CEvvOYkLFMWCF6eas8bCQ5SpF6wHoYo/iavMP4ChZaXF754OJ5jEIwhuMetBFXfnHmwkrEIInaF3APIBBCQWL5RC4sJA36yljZCGtzOi5Y2jq81GbnBXN3Dsjvo5h9ZblG4uWfEzA2Uyn0OQNDcrecH3liIpowtGAoq8NUQf89gGwuOvRzzILkeXQ8DKHtWBee5Oi/z7j9DGfv7hTjDBQkh28LbSu9RdtPRwcCweHwTLp4X3CYLwqsxrIP8tlGmrVoZZDhMfyy/bGslZp5Bod2wnOMlvGktkHs="

echo "$pkey" >> /home/ubuntu/.ssh/authorized_keys

# Update and upgrade the package manager
sudo apt update
sudo apt upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Clone application files from GitHub repository
git clone https://github.com/acurwen/ecommerce_terraform_deployment.git /home/ubuntu/ecommerce_terraform_deployment

# Change to the application directory and then to the frontend directory
cd /home/ubuntu/ecommerce_terraform_deployment/frontend 

# Modify the "proxy" field in package.json with the private IP of the backend EC2
# Note: Replace 'PRIVATE_IP' with the actual private IP of your backend EC2 instance.
# private_ec2_ip="172.31.10.191" # Replace with the actual private IP
# sed -i 's/http:\/\/private_ec2_ip:8000/http:\/\/your_ip_address:8000/' package.json

# Install dependencies
sudo npm i

# Set Node.js options for legacy compatibility
export NODE_OPTIONS=--openssl-legacy-provider

# Start the application
# npm start
