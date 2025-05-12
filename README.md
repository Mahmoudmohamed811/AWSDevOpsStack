# AWS Terraform Project Documentation

Welcome to the documentation for the AWS Terraform project. This guide provides an overview of the infrastructure, deployment steps, and troubleshooting tips for managing a web application hosted on AWS EC2 with a MySQL RDS backend, deployed using Terraform and Docker.

---

## 📋 Project Overview



![image](https://github.com/user-attachments/assets/0afe6e37-35bd-4df7-b1e1-ca0be8cf842d)


This project deploys a web application on AWS using Terraform to provision infrastructure. The application runs in a Docker container on an EC2 instance, connects to a MySQL RDS database, and is accessible via HTTP (port 80). Terraform state is managed in an S3 bucket for team collaboration.

**Key Components**:

- **VPC**: A custom VPC with public and private subnets.
- **EC2**: Hosts the web application in a Docker container (`mahmoudmabdelhamid/getting-started`).
- **RDS**: MySQL database for persistent storage.
- **Security Groups**: Controls traffic to EC2 (HTTP) and RDS (MySQL).
- **Docker**: Runs the application, mapping port 3000 (container) to 80 (host).
- **S3 Backend**: Stores Terraform state file for shared state management.

**Objective**: Provide a scalable, modular infrastructure for a web application with a database backend.

---

## 🏗️ Architecture

### VPC

- **CIDR Block**: `10.0.0.0/16`
- **Subnets**:
    - Public Subnet1: `10.0.0.0/24` (us-east-1a)
    - Public Subnet2: `10.0.2.0/24` (us-east-1b)
    - Private Subnet: `10.0.1.0/24` (us-east-1b)
- **Internet Gateway**: Enables public subnet internet access.
- **NAT Gateway**: Allows private subnet instances to access the internet.
- **Route Tables**:
    - Public: Routes to Internet Gateway.
    - Private: Routes to NAT Gateway.

### EC2

- **AMI**: `ami-0e449927258d45bc4` (Amazon Linux 2)
- **Instance Type**: `t2.micro`
- **Subnet**: Public subnet
- **Security Group**: Allows inbound HTTP (port 80) and all outbound traffic.
- **User Data**: Script (`user_data.sh.tpl`) to:
    - Set environment variables for MySQL connection.
    - Update the system and install MariaDB client (`mariadb105`).
    - Install Docker and start the service.
    - Create the MySQL database on RDS.
    - Pull and run the `mahmoudmabdelhamid/getting-started` Docker container.

**User Data Script Details** (`modules/ec2/templates/user_data.sh.tpl`):

```bash
#!/bin/bash
echo "export MYSQL_PASSWORD=${MYSQL_PASSWORD}" >> /etc/profile.d/env-vars.sh
echo "export MYSQL_DB=${MYSQL_DB}" >> /etc/profile.d/env-vars.sh
echo "export MYSQL_USER=${MYSQL_USER}" >> /etc/profile.d/env-vars.sh
echo "export MYSQL_HOST=${MYSQL_HOST}" >> /etc/profile.d/env-vars.sh
chmod +x /etc/profile.d/env-vars.sh
source /etc/profile.d/env-vars.sh

# Update the system
yum -y update

# Install MariaDB client to interact with the RDS database
dnf install -y mariadb105

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker

# Create the database if it doesn't exist
mysql -h "${MYSQL_HOST}" -P 3306 -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DB};"

# Pull and run the Docker image
docker pull mahmoudmabdelhamid/getting-started
docker run -d -p 80:3000 --name getting-started \\
  -e MYSQL_HOST="${MYSQL_HOST}" \\
  -e MYSQL_USER="${MYSQL_USER}" \\
  -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \\
  -e MYSQL_DB="${MYSQL_DB}" \\
  mahmoudmabdelhamid/getting-started

```

- **Purpose**: Configures the EC2 instance to run the web application by installing dependencies, setting up the database, and launching the Docker container.
- **Variables**: Uses Terraform variables (`MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`) passed from the EC2 module.

### RDS

- **Engine**: MySQL 5.7
- **Instance Class**: `db.t3.micro`
- **Storage**: 20GB (gp2)
- **Subnet Group**: Spans public and private subnets
- **Security Group**: Allows MySQL (port 3306) from EC2’s security group
- **Credentials**: Configured via Terraform variables (`MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`)

### Security Groups

| Security Group | Rule Type | Protocol | Port | Source/Destination | Description |
| --- | --- | --- | --- | --- | --- |
| `web-sg` | Ingress | TCP | 80 | 0.0.0.0/0 | Allow HTTP traffic to web server |
| `web-sg` | Egress | All | 0-65535 | 0.0.0.0/0 | Allow all outbound traffic (e.g., Docker Hub, RDS, package repos) |
| `web-sg` | Ingress | TCP | 22 | `web-sg` | Allow SSH traffic |
| `rds-sg` | Ingress | TCP | 3306 | `web-sg` | Allow web server to access RDS |

### 📄 **Application Load Balancer (ALB) Configuration**

This Terraform setup provisions a public-facing **Application Load Balancer (ALB)** that distributes HTTP traffic across two EC2 instances. It includes:

- An ALB in two public subnets with a listener on port 80.
- A target group with health checks on `/` to monitor instance availability.
- Two EC2 instances registered as targets, each listening on port 80.

This configuration enables **high availability**, **automatic health monitoring**, and **scalable traffic distribution** through a single DNS endpoint.

### Docker

- **Image**: `mahmoudmabdelhamid/getting-started`
- **Port Mapping**: 3000 (container) to 80 (host)
- **Environment Variables**:
    - `MYSQL_HOST`: RDS endpoint
    - `MYSQL_USER`: Database user
    - `MYSQL_PASSWORD`: Database password
    - `MYSQL_DB`: Database name (`todos`)

### Terraform State Management

Terraform state is stored in an S3 bucket to enable team collaboration and state consistency.

**Configuration** (`main.tf`):

```hcl
terraform {
  backend "s3" {
    bucket = "my-state-file-terraform-bucket"
    key    = "statefile.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}

```

- **Bucket**: `my-state-file-terraform-bucket` (in `us-east-1`)
- **Key**: `statefile.tfstate`
- **Region**: `us-east-1`
- **Locking**: S3 native locking is used.

**Setup Instructions**:

1. **Create S3 Bucket**:
    - In AWS Console, create a bucket named `my-state-file-terraform-bucket` in `us-east-1`.

---

## 🚀 Deployment Instructions

### Prerequisites

- **AWS Account**: Configured with access keys.
- **Terraform**: Installed (version compatible with `hashicorp/aws ~> 5.0`).
- **S3 Bucket**: `my-state-file-terraform-bucket` in `us-east-1.`

### Steps

1. **Set Up S3 Backend**:
    - Create the S3 bucket `my-state-file-terraform-bucket` in `us-east-1` (see “Terraform State Management”).
2. **Clone the Repository**:
    
    ```bash
    git clone <your-repo-url>
    cd <repo-directory>
    
    ```
    
3. **Configure Variables**:
    - Edit `variables.tf` to set `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_DB` (defaults: `root`, `YUSSUFyasser`, `todos`).
    - Alternatively, create a `terraform.tfvars` file:
        
        ```hcl
        MYSQL_USER = "root"
        MYSQL_PASSWORD = "YUSSUFyasser"
        MYSQL_DB = "todos"
        
        ```
        
4. **Initialize Terraform**:
    
    ```bash
    terraform init
    
    ```
    
    - This configures the S3 backend and copies any local state to `my-state-file-terraform-bucket/statefile.tfstate`.
5. **Plan and Apply**:
    
    ```bash
    terraform plan
    terraform apply
    
    ```
    
    - Confirm by typing `yes` when prompted.
6. **Access the Application**:
    - Get the EC2 instance’s public IP from the AWS Console or Terraform output.
    - Open `http://<public-ip>` in a browser to access the application.

### Post-Deployment

- **Verify Docker Container**:
    - SSH into the EC2 instance: `ssh -i <your-key>.pem ec2-user@<public-ip>`
    - Check Docker: `docker ps -a`
    - View container logs: `docker logs getting-started`
- **Check RDS**:
    - Use the MySQL client: `mysql -h <rds-endpoint> -P 3306 -u root -pYUSSUFyasser`
    - Verify the `todos` database exists: `SHOW DATABASES;`
- **Verify State File**:
    - Check the S3 bucket `my-state-file-terraform-bucket` in the AWS Console.
    - Confirm `statefile.tfstate` exists and is updated after `terraform apply`.

## 📡 **Final Architecture Overview**

![image](https://github.com/user-attachments/assets/d0aeb79c-9ad8-46b5-bb0d-9f02c4e17bac)
![image](https://github.com/user-attachments/assets/11df7516-bf3c-42b8-8bbc-517c5e298f4f)


##
