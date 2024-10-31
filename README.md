
# Kura Labs Cohort 5- Deployment Workload 5

# Purpose:

A new E-Commerce company wants to deploy their application to AWS Cloud Infrastructure that is secure, available, and fault tolerant.  They also want to utilize Infrastructure as Code as well as a CICD pipeline to be able to spin up or modify infrastructure as needed whenever an update is made to the application source code.  As a growing company they are also looking to leverage data and technology for Business Intelligence to make decisions on where to focus their capital and energy on. 

# Steps Taken:

## Deploying Application Locally:
1. Create 2 t3.micro EC2s to represent the "Frontend" and "Backend"
- Frontend Ports should be 22 and 3000 (for Node.js)
- Backend Ports should be for 22 ans 8000 (for Django)

![image](https://github.com/user-attachments/assets/d23c87f3-1c87-4516-9843-1b3a5cb53cda)

- Create the "Frontend Test" EC2 in the default public subnet.
- Create the "Backend Test" EC2 in your newly made private subnet. (Disable auto-assign of a public IP and create and save a new keypair.)
*Availability Zone in this example was us-east-1d for both subnets.
- Associate the default public subnet (where the Frontend EC2 is) to the default route table that includes the default Internet Gateway as a route. 
- Create a NAT Gateway and a new route table. Associate the new route table with the private subnet where the Backend Test EC2 is and add the NAT Gateway as a route in the route table.


------------------------------------------
**SSHing into Backend EC2:**

When launching the Backend EC2, a new key pair should be created and saved to your local machine. WhiLe in the Frontend EC2:
1. Nano a new .pem file and copy and paste the key pair into it.
2. Update permissions of the file with `chmod 400 file_name.pem`.
3. Test if you can SSH into the Backend EC2 using the name of the file with `ssh -i file_name.pem ubuntu@172.31.166.242`

   
------------------------------------------
**Django Setup in Backend EC2:**
While SSH'd into the Backend EC2:
1. Git clone the application files from your GitHub repository.
2. Run `sudo apt update` and `sudo apt upgrade -y`
3. Run `sudo apt install software-properties-common && sudo add-apt-repository ppa:deadsnakes/ppa -y`
4. Run `sudo apt install python3.9 python3.9-venv python3.9-dev -y`
5. Cd into application file directory. 
6. Run `python3.9 -m venv venv` to create virtual environment
7. Run `source venv/bin/activate` to activate virtual environment
8. Cd into backend folder
9. Run `pip install -r requirements.txt`
10. Cd into my_project directory
11. Nano into settings.py and update "ALLOWED_HOSTS" with the private IP of the Backend EC2. Make sure syntax is ALLOWED_HOSTS = ['private_ip']. *Include the single quotes*
12. Run `cd ..` to go back up a folder - back to the backend folder
13. Run python manage.py runserver 0.0.0.0:8000 to start the Django server
    
------------------------------------------
**Node.js Setup in Frontend EC2:**
While in the Frontend EC2:
1. Git clone application files from your GitHub repository.
2. Run `sudo apt update` and `sudo apt upgrade -y`
3. Run `curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -` and `sudo apt install -y nodejs` to install Node.js and npm
4. Cd into application file directory and then into the frontend directory.
5. Nano into package.json and modify the "proxy" field with the private IP of the backend EC2 (http://private_IP:8000)
6. Run `npm i` to install the dependencies
7. Run `export NODE_OPTIONS=--openssl-legacy-provider` to set Node.js options for legacy compatibility
8. Run 'npm start' to start the app. Navigate to Frontend_public_IP:3000 in a web browser to verify that the application is running.

Application:
![image](https://github.com/user-attachments/assets/313ff87d-e76a-4613-8c9a-29c4077914fd)

What the page looks like if the Django server is stopped:
![image](https://github.com/user-attachments/assets/82f66ffa-c58d-48a2-b222-67b991aea6a0)

------------------------------------------
**What is the tech stack?**

**What is Node.js?** It is a Javascript framework that handles the backend. It can connect to the database to retrieve information and also process data, application logic and API requests. It can also send back responses to the frontend.

**What is Django?** It is a Python framework used to run the frontend. It can communicate with Django for data, acting as a middleman between Django and the frontend. Django manages the user experience and is able to show data to users (in HTML, CSS & Javascript) and captures the input of the user.

When you are done with your local deployment, you can delete the 2 EC2's you created.

------------------------------------------

## IaC and a CICD pipeline

1. Create an EC2 t3.medium called "Jenkins_Terraform" for Jenkins and Terraform.
Properties:
- AMI: Ubuntu
- Default VPC
- Availability Zone: us-east-1a
- Default public subnet
- Enable auto-assign public IP
- Security group with open ports: 22, 8080 (Jenkins), 8081 (VSCode)

2. Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli), Jenkins and [VSCode](https://github.com/kura-labs-org/install-sh/blob/main/vscode_install.sh)

3. Navigate to VSCode GUI on port 8081 and create a new directory for Terraform.

------------------------------------------

## Terraform (IaC)

1. Within your new Terraform directory, create main.tf, variables.tf and terraform.auto.vars.

Tips to keep in Mind:
- Ensure your subnets don't have coinciding CIDR blocks
- Ensure access and secret key match your IAM user
- Ensure the key_name for your frontend EC2s exist
- Create and save the .pem keys created for the backend EC2s

2. Create the following resource blocks required for the infrastructure below:
```
- 1x Custom VPC named "wl5vpc" in us-east-1
- VPC Peering Connection (Between Custom VPC & Default VPC)
- 2x Availability zones in us-east-1a and us-east-1b
- A Private and Public Subnet in Availability Zone: us-east-1a
- A Private and Public Subnet in Availability Zone: us-east-1b
- Internet Gateway
- Public Route Table w/ Internet Gateway (can be used for both public subnets)
- Public Route Table Association with both Public Subnets
- 2 NAT Gateways
- 2 Elastic IPs for each NAT Gateway
- Private Route Table
- Private Route Table #1 w/ NAT Gateway
- Private Route Table Association with Private Subnet #1
- Private Route Table #2 w/ NAT Gateway
- Private Route Table Association with Private Subnet #2
- 4 EC2s to be placed in each subnet (EC2s in the public subnets are for the frontend, the EC2s in the private subnets are for the backend. Name the EC2's: "ecommerce_frontend_az1", "ecommerce_backend_az1", "ecommerce_frontend_az2", "ecommerce_backend_az2")
- Security Groups for each EC2 (Frontend SG Ports should be 22, 3000 and Backend SG Ports should be 22, 8000 & 9100)
- Load Balancer that will direct the inbound traffic to either of the public subnets.
- Target Group for Load Balancer: Define a target group to register your frontend instances, where the load balancer will forward traffic.
- Target Group Attachments
- Load Balancer Listener
- Security Group for Load Balancer 
- Health Checks for Load Balancer: Define these to ensure that traffic only routes to healthy frontend instances
- An RDS database
- RDS Subnet Group: Required by RDS, which specifies which subnets the database instance can run in (typically private subnets)
- Security Group for RDS
```

Write two scripts to set up the frontend and backend setup - these will be put in the user_data section of your provider blocks for each EC2.
You can first test these scripts manually in an EC2 to ensure they work as intended. 

Things to do MANUALLY after running `terraform apply`:
1. In the Frontend EC2s, navigate to application directory/frontend/ and sudo nano into package.json and modify the "proxy" field with the private IP of the backend EC2 (http://private_IP:8000).
2. Also update the "status" field in the "scripts" section to have "DANGEROUSLY_DISABLE_HOST_CHECK=true HOST=0.0.0.0 PORT=3000 react-scripts start", --> This is to help get the Load Balancer working.
3. Run these commands in terminal to save the new private keys to a file
   - terraform output -raw backend_private_key1 > backend-key1.pem
   - terraform output -raw backend_private_key2 > backend-key2.pem
4. Copy these files into each Frontend EC2 and update permissions of each file with `chmod 400 file_name.pem`.
5. SSH into the Backend EC2 with ssh -i file_name.pem ubuntu@private_ip`
6. In the Backend EC2s, sudo nano into application directory/backend/my_project/settings.py and update "ALLOWED_HOSTS" with the private IP of the Backend EC2. Make sure syntax is ALLOWED_HOSTS = ['private_ip']. *Include the single quotes*
7. Still in settings.py, update the 'ENGINE' field with the hard-coded credentials from your RDS Database block in your main.tf Terraform file. Navigate to RDS database page in AWS to find endpoint for 'HOST' field. Also uncomment lines 96 and 97.

Fields:
- 'NAME': 'W5Database',
- 'USER': 'itsme2',
- 'PASSWORD': 'lemondifficult3',
- 'HOST': 'ecommerce-db.cjcw6akqimir.us-east-1.rds.amazonaws.com', 
- 'PORT': '5432',
  
9. Navigate into application directory and activate virtual environment: `source venv/bin/activate`
10. Navigate into backend directory and run the below database loading commands (First run sudo chmod -R 755 /home/ubuntu/ecommerce_terraformdeployment/backend/). Run the last line ONLY in one private instance. 

LOAD THE DATABASE INTO RDS:
```
# Create the tables in RD
python manage.py makemigrations account
python manage.py makemigrations payments
python manage.py makemigrations product
python manage.py migrate

# Migrate the data from SQLite file to RDS:
python manage.py dumpdata --database=sqlite --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 4 > datadump.json

# Last line to only run in backend EC2
python manage.py loaddata datadump.json
```
If you receive an error regarding a too lengthy char input, update backend/account/models.py and change max length of card number to 20

11. Run Django server with `python manage.py runserver 0.0.0.0:8000`

12. In Frontend EC2, run `curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -` and `sudo apt install -y nodejs` to install Node.js and npm
Run `sudo chown -R ubuntu:ubuntu /home/ubuntu/ecommerce_terraform_deployment/frontend`
13. Navigate to application directory/frontend
14.  Run `npm i` to install the dependencies
15.  Run `export NODE_OPTIONS=--openssl-legacy-provider` to set Node.js options for legacy compatibility
16. Run 'npm start' to start the app. Navigate to Frontend_public_IP:3000 in a web browser to verify that the application is running.

   
## Jenkins Pipeline

Edit the Jenkinsfile with the stages: "Build", "Test", "Init", "Plan", and "Apply" that will build the application, test the application, run the Terraform commands to create the infrastructure and deploy the application.

"Build":
- create virtual environment
- activate virtual environment
- install pip
- install requirements.txt

"Test":
- activate virtual environment
- (tests have already been created for this workload)

"Init":
- run `terraform init`

"Plan":
- run `terraform plan`
- Make sure access keys and secret keys are not uploaded to GH, but instead saved as secret texts in your Security Credentials in Jenkins.

"Apply":
- run `terraform apply`

(GH repository that is used in your build should have your Terraform files and scripts [for user_data sections] in it.)

Again, whatever setup that is not included in your user_data scripts has to be done manually once the infrastrucure is set up. 
Steps:
In Jenkins_Terraform EC2, run: 
```
terraform output -raw backend_private_key1 > backend-keyone.pem
terraform output -raw backend_private_key2 > backend-keytwo.pem
```

![image](https://github.com/user-attachments/assets/18870ddf-80ee-4b73-a8b0-ecceef67a7e6)


## Monitoring
In whatever instance you're monitoring, install Node Exporter with [nodex.sh](https://github.com/mmajor124/monitorpractice_promgraf/blob/main/nodex.sh)

Before running nodex.sh, I comment out lines #41 onwards, since Prometheus and Grafana will be installed on another EC2 for Monitoring.

Create a t3.micro EC2 called "Monitoring" in the default VPC that will monitor the resources of the various servers. Include ports 22, 9090 for Prometheus and 3000 for Grafana if you want to include visualizations.

To install Grafana and Prometheus, run promgraf.sh.
Check that both are up an running with:
`sudo systemctl status grafana-server` & `sudo systemctl status prometheus`

Next, run these commands in the terminal:
```
# Add Node Exporter job to Prometheus config
cat << EOF | sudo tee -a /opt/prometheus/prometheus.yml

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

Then I ran sudo nano /opt/prometheus/prometheus.yml to doublecheck that the lines were added to my prometheus.yml file.

# Restart Prometheus to apply the new configuration
sudo systemctl restart prometheus
```
Lastly, check the targets in the Prometheus GUI (Port 9090) to ensure your endpoints are "UP".


## System Design Diagram 
![image](https://github.com/user-attachments/assets/235a2de1-f1a3-44fe-adf9-5205f42e26aa)

## Issues/Troubleshooting 
My load balancer kept running a 502 Bad gateway error. In the resource map, it showed that both targets (both my frotn end EC2s were unhealthy checks. 
![image](https://github.com/user-attachments/assets/d1778c44-b0e3-4c3f-bb85-902c7ed37674)

Unfortunately, I had a process where after my Terraform apply happens, I run commands in the terminal to save the .pem keys made for my backend instances into files I can access. However, I got an error when I ran these files in my Jenkins_Terraform EC2 that no outputs were fine. Running these commands in my VSCode terminal worked fine prior. 
![image](https://github.com/user-attachments/assets/058fd688-9fb5-435a-8b84-09d68d5b7c3f)
I tried changing the sensitive = false for these two keys in my main.tf file, however, I Ran into an error with my Jenkins pipeline. I believe I needed another header in my outputs section that confirmed "yes" I want these .pem keys open.

I also had an issue where I tried to destroy my terraform via VSCode after running Jenkins but I was locked out so I added a "Destroy" stage in my Jenkins file, but again error. 
![image](https://github.com/user-attachments/assets/8cb33f31-eddf-45ab-9080-61bff2fb3b3e)


## Business Intelligence
From your backend EC2 terminal:
1. First, install postgressql with `sudo apt install -y postgresql-client`
2. Then run `psql -h <RDS-endpoint> -U <username> -d <database>` to use the psql to connect to the database. (Remove the carats <>).
3. Enter your database password when prompted.

Diagram of the schema and relationship between the tables:

![image](https://github.com/user-attachments/assets/bcfb62d5-f0d5-401b-a846-d91faf85c387)

   
Number of rows in each table:
"auth_user": 11
"product": 6
"account_billing_address": 14
"account_stripemodel": 13
"account_ordermodel": 11


## Optimization:
All parts of my infrastructure were created using terraform, however a lot of what I wanted to run in my user_data scripts section did not work. So once my EC2s were setup, I manually did most of the frontend and backend setup. I also had Terraform output the private IPs of my backend servers and the .pem keys that were created with them in order for me to finish setup with SSH. Moving forward, utilizing variables could help me optimize this system more.

Secondly, to organize my resource blocks better and utilize variables I can implement modules for each "section" of my infrastrucuture instead of having one master main.tf file. 

## Conclusion:
This deployment helped me to understand the various moving parts of creating infrastructure with Terraform and how many resource blocks are needed to deploy this application.

