#!/bin/bash

# public_key for Codon
pkey="ssh-rsaAAAAB3NzaC1yc2EAAAADAQABAAABgQDSkMc19m28614Rb3sGEXQUN+hk4xGiufU9NYbVXWGVrF1bq6dEnAD/VtwM6kDc8DnmYD7GJQVvXlDzvlWxdpBaJEzKziJ+PPzNVMPgPhd01cBWPv82+/Wu6MNKWZmi74TpgV3kktvfBecMl+jpSUMnwApdA8Tgy8eB0qELElFBu6cRz+f6Bo06GURXP6eAUbxjteaq3Jy8mV25AMnIrNziSyQ7JOUJ/CEvvOYkLFMWCF6eas8bCQ5SpF6wHoYo/iavMP4ChZaXF754OJ5jEIwhuMetBFXfnHmwkrEIInaF3APIBBCQWL5RC4sJA36yljZCGtzOi5Y2jq81GbnBXN3Dsjvo5h9ZblG4uWfEzA2Uyn0OQNDcrecH3liIpowtGAoq8NUQf89gGwuOvRzzILkeXQ8DKHtWBee5Oi/z7j9DGfv7hTjDBQkh28LbSu9RdtPRwcCweHwTLp4X3CYLwqsxrIP8tlGmrVoZZDhMfyy/bGslZp5Bod2wnOMlvGktkHs="


echo "$pkey" >> /home/ubuntu/.ssh/authorized_keys


# Node Exporter
# Install wget if not already installed
sudo apt install wget -y

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.5.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create a Node Exporter user
sudo useradd --no-create-home --shell /bin/false node_exporter

# Create a Node Exporter service file
cat << EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start and enable Node Exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Print the public IP address and Node Exporter port
echo "Node Exporter installation complete. It's accessible at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9100/metrics"

# Clone the application files from your GitHub repository
git clone https://github.com/acurwen/ecommerce_terraform_deployment.git /home/ubuntu/ecommerce_terraform_deployment


# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install necessary software and add the deadsnakes PPA for Python
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y

# Install Python 3.9 and related packages
sudo apt install python3.9 python3.9-venv python3.9-dev -y

# Change to the application directory
cd /home/ubuntu/ecommerce_terraform_deployment

# Create a virtual environment
sudo python3.9 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Change to the backend folder
cd backend

# Install Python dependencies
pip install --upgrade pip
pip install -r /home/ubuntu/ecommerce_terraform_deployment/backend/requirements.txt

# # Change to my_project directory
# cd my_project

# # Update ALLOWED_HOSTS in settings.py with the private IP of the backend EC2
# PRIVATE_IP="172.31.10.191" # Replace with the actual private IP
# # Modify the ALLOWED_HOSTS line in settings.py
# sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ['$PRIVATE_IP']/g" settings.py

# # Navigate back to the backend folder
# cd ..

echo "NOW LOAD DB AND START DJANGO SERVER..."

# Start the Django server
# python manage.py runserver 0.0.0.0:8000
