# AWS Terraform Project Documentation

Welcome to the documentation for the AWS Terraform project. This guide provides an overview of the infrastructure, deployment steps, and troubleshooting tips for managing a web application hosted on multiple AWS EC2 instances behind an Application Load Balancer (ALB), with a MySQL RDS backend, deployed using Terraform and configured with Ansible.

---

## 📋 Project Overview



![image](https://github.com/user-attachments/assets/0afe6e37-35bd-4df7-b1e1-ca0be8cf842d)


This project deploys a web application on AWS using Terraform to provision infrastructure and an Ansible playbook to configure multiple EC2 instances. The application runs in Docker containers, connects to a MySQL RDS database, and is accessible via HTTP (port 80) through an ALB. Terraform state is managed in an S3 bucket, and Terraform outputs are passed to Ansible for configuration.

**Key Components**:
- **VPC**: A custom VPC with public and private subnets.
- **ALB**: Application Load Balancer to distribute traffic to EC2 instances.
- **EC2**: Multiple instances hosting the web application in Docker containers (`mahmoudmabdelhamid/getting-started`).
- **RDS**: MySQL database for persistent storage.
- **Security Groups**: Controls traffic to ALB (HTTP), EC2 (HTTP from ALB, SSH), and RDS (MySQL from EC2).
- **Docker**: Runs the application, mapping port 3000 (container) to 80 (host).
- **S3 Backend**: Stores Terraform state file.
- **Ansible Playbook**: Configures EC2 instances post-launch.

**Objective**: Provide a scalable, load-balanced infrastructure for a web application with a database backend.

---

## 🏗️ Architecture

### VPC
- **CIDR Block**: `10.0.0.0/16`
- **Subnets**:
  - Public Subnet: `10.0.0.0/24` (us-east-1a)
  - Private Subnet: `10.0.1.0/24` (us-east-1b)
- **Internet Gateway**: Enables public subnet internet access.
- **NAT Gateway**: Allows private subnet instances to access the internet.
- **Route Tables**:
  - Public: Routes to Internet Gateway.
  - Private: Routes to NAT Gateway.

### ALB
- **Type**: Application Load Balancer
- **Subnet**: Public subnet
- **Security Group**: Allows inbound HTTP (port 80) from `0.0.0.0/0` and all outbound traffic.
- **Target Group**: Forwards traffic to EC2 instances on port 80.
- This configuration enables **high availability**, **automatic health monitoring**, and **scalable traffic distribution** through a single DNS endpoint.

### EC2
- **AMI**: `ami-0e449927258d45bc4` (Amazon Linux 2)
- **Instance Type**: `t2.micro`
- **Count**: 2 (e.g., IPs: `54.146.144.1`, `107.21.176.13`)
- **Subnet**: Public subnet
- **Security Group**: Allows inbound HTTP (port 80) from ALB, SSH (port 22, temporary for Ansible), and all outbound traffic.
- **Configuration**: Managed by an Ansible playbook (`playbooks/setup_ec2.yml`), which:
  - Sets environment variables in `/etc/profile.d/env-vars.sh`.
  - Updates system packages (`yum -y update`).
  - Installs MariaDB client (`mariadb`).
  - Installs and starts Docker.
  - Creates the MySQL database on RDS.
  - Pulls and runs the `mahmoudmabdelhamid/getting-started` Docker container.

**Ansible Playbook** (`playbooks/setup_ec2.yml`):
```yaml
---
- name: Update system packages
  ansible.builtin.yum:
    name: '*'
    state: latest
    update_cache: yes

- name: Install MariaDB client
  ansible.builtin.yum:
    name: mariadb105
    state: present

- name: Install Docker
  ansible.builtin.yum:
    name: docker
    state: present

- name: Start and enable Docker service
  ansible.builtin.service:
    name: docker
    state: started
    enabled: yes

- name: Add ec2-user to docker group
  ansible.builtin.user:
    name: ec2-user
    groups: docker
    append: yes

- name: Create MySQL database if it doesn’t exist
  ansible.builtin.command:
    cmd: mysql -h {{ mysql_host }} -P 3306 -u {{ mysql_user }} -p{{ mysql_password }} -e "CREATE DATABASE IF NOT EXISTS {{ mysql_db }};"
  changed_when: false

- name: Pull Docker image
  ansible.builtin.docker_image:
    name: mahmoudmabdelhamid/getting-started
    source: pull

- name: Run Docker container
  ansible.builtin.docker_container:
    name: getting-started
    image: mahmoudmabdelhamid/getting-started
    state: started
    restart_policy: always
    ports:
      - "80:3000"
    env:
      MYSQL_HOST: "{{ mysql_host }}"
      MYSQL_USER: "{{ mysql_user }}"
      MYSQL_PASSWORD: "{{ mysql_password }}"
      MYSQL_DB: "{{ mysql_db }}"
```

**Inventory File** 
```ini
[webserver]
54.146.144.1 ansible_user=ec2-user ansible_ssh_private_key_file=~/projects/terra/Terraform_AWS_Project/keys/my-key.pem ansible_python_interpreter=/usr/bin/python3
107.21.176.13 ansible_user=ec2-user ansible_ssh_private_key_file=~/projects/terra/Terraform_AWS_Project/keys/my-key.pem ansible_python_interpreter=/usr/bin/python3
```

- **Purpose**: Configures the EC2 instance to run the web application by installing dependencies, setting up the database, and launching the Docker container.

### RDS

- **Engine**: MySQL 5.7
- **Instance Class**: `db.t3.micro`
- **Storage**: 20GB (gp2)
- **Subnet Group**: Spans public and private subnets
- **Security Group**: Allows MySQL (port 3306) from EC2’s security group
- **Credentials**: Configured via Terraform variables (`MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`)

### Security Groups

### Security Groups
| Security Group | Rule Type | Protocol | Port | Source/Destination | Description |
|----------------|-----------|----------|------|--------------------|-------------|
| `alb-sg`       | Ingress   | TCP      | 80   | 0.0.0.0/0          | Allow HTTP traffic to ALB |
| `alb-sg`       | Egress    | All      | 0-65535 | 0.0.0.0/0       | Allow all outbound traffic (e.g., to EC2) |
| `web-sg`       | Ingress   | TCP      | 80   | `alb-sg`           | Allow HTTP traffic from ALB |
| `web-sg`       | Ingress   | TCP      | 22   | 0.0.0.0/0          | Allow SSH for Ansible (restrict to your IP in production) |
| `web-sg`       | Egress    | All      | 0-65535 | 0.0.0.0/0       | Allow all outbound traffic (e.g., Docker Hub, RDS) |
| `rds-sg`       | Ingress   | TCP      | 3306 | `web-sg`           | Allow MySQL traffic from EC2 |


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

 **Create S3 Bucket**:
    - In AWS Console, create a bucket named `my-state-file-terraform-bucket` in `us-east-1`.

---

## 🚀 Deployment Instructions

### Prerequisites
- **AWS Account**: Configured with access keys.
- **Terraform**: Installed (version compatible with `hashicorp/aws ~> 5.0`).
- **Ansible**: Installed (`pip install ansible`).
- **S3 Bucket**: `my-state-file-terraform-bucket` in `us-east-1` for state storage.
- **SSH Key**: AWS key pair (`my-key.pem`) at `~/projects/terra/Terraform_AWS_Project/keys/my-key.pem`.

### Steps

1. **Set Up S3 Backend**:
   - Create `my-state-file-terraform-bucket` in `us-east-1` with versioning enabled (see “Terraform State Management”).
   - Apply bucket policy and IAM permissions.
2. **Set Up Ansible**:
   - Install Ansible: `pip install ansible`.
   - Install Docker collection: `ansible-galaxy collection install community.docker`.
   - Create `playbooks/setup_ec2.yml` with the provided playbook.
   - Ensure `inventory.ini` and `vars.yml` are generated by Terraform.
3. **Clone the Repository**:
   ```bash
   git clone <your-repo-url>
   cd <repo-directory>
   ```
4. **Configure Variables**:
   - Edit `variables.tf` or create `terraform.tfvars`:
     ```hcl
     MYSQL_USER = "root"
     MYSQL_PASSWORD = "YUSSUFyasser"
     MYSQL_DB = "todos"
     ssh_private_key_path = "~/projects/terra/Terraform_AWS_Project/keys/my-key.pem"
     ```
   - Update `main.tf` with SSH key details:
     ```hcl
     module "ec2" {
       key_name            = "my-key"
       ssh_private_key_path = "~/projects/terra/Terraform_AWS_Project/keys/my-key.pem"
     }
     ```
5. **Initialize Terraform**:
   ```bash
   terraform init
   ```
   - Syncs with `my-state-file-terraform-bucket/statefile.tfstate`.
6. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply
   ```
   - Confirm by typing `yes`.
   - Terraform launches the ALB, EC2 instances, and RDS, generates `inventory.ini` and `vars.yml`, and triggers the Ansible playbook.
7. **Access the Application**:
   - Get the ALB DNS name: `terraform output alb_dns_name` or AWS Console (Elastic Load Balancing > Load Balancers).
   - Open `http://<alb-dns-name>` in a browser.

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
