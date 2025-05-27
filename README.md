# AWSDevOpsStack: Scalable Todo App Pipeline

AWSDevOpsStack deploys a scalable todo list web application on AWS, using Terraform for infrastructure, Ansible for configuration, Jenkins for CI/CD, Docker for containerization, and Prometheus, Grafana, and Node Exporter for monitoring. The app runs on EC2 instances behind an Application Load Balancer (ALB), connected to a MySQL RDS database. Scripts automate inventory and Prometheus setup, executed via Jenkins.

## Project Overview

![Image](https://github.com/user-attachments/assets/d8385ff9-9f7d-4f5a-9227-1168c488e110)

This project demonstrates a production-ready DevOps pipeline with:

- Infrastructure: VPC, ALB, EC2, RDS provisioned by Terraform.
- Configuration: Ansible playbooks for EC2 and monitoring.
- CI/CD: Jenkins pipeline automating scripts, Terraform, Ansible.
- Monitoring: Prometheus, Grafana, Node Exporter for metrics.
- Containerization: Dockerized app (mahmoudmabdelhamid/getting-started).
- Scripts: Automate inventory and Prometheus configuration.
- State Management: Terraform state in S3 bucket.

**Objective**: Showcase scalable infrastructure, automation, and monitoring, aligning with CKA and AWS Cloud Practitioner certifications.

## Architecture

- **VPC**: CIDR 10.0.0.0/16.
    - Public Subnets: 10.0.0.0/24 (us-east-1a), 10.0.2.0/24 (us-east-1b), 10.0.3.0/24 (us-east-1c, for monitoring).
    - Private Subnet: 10.0.1.0/24 (us-east-1b).
- **ALB**: Distributes HTTP traffic to EC2 instances.
- **EC2**: Web, Prometheus, Grafana instances running Docker.
- **RDS**: MySQL database for persistent storage.
- **Monitoring**: Prometheus, Grafana, Node Exporter.
- **CI/CD**: Jenkins automates deployment pipeline.
- **S3**: Stores Terraform state.

### Security Groups

| Security Group | Rule Type | Protocol | Port | Source/Destination | Description |
| --- | --- | --- | --- | --- | --- |
| alb-sg | Ingress | TCP | 80 | 0.0.0.0/0 | HTTP to ALB |
| alb-sg | Egress | All | 0-65535 | 0.0.0.0/0 | Outbound traffic |
| web-sg | Ingress | TCP | 80 | alb-sg | HTTP from ALB |
| web-sg | Ingress | TCP | 22 | 0.0.0.0/0* | SSH (restrict in production) |
| web-sg | Ingress | TCP | 9100 | prometheus-sg | Node Exporter from Prometheus |
| web-sg | Egress | All | 0-65535 | 0.0.0.0/0 | Outbound traffic |
| rds-sg | Ingress | TCP | 3306 | web-sg | MySQL from EC2 |
| rds-sg | Egress | All | 0-65535 | 0.0.0.0/0 | Outbound traffic |
| prometheus-sg | Ingress | TCP | 22 | 0.0.0.0/0* | SSH (restrict in production) |
| prometheus-sg | Ingress | TCP | 9090 | 0.0.0.0/0* | Prometheus UI |
| prometheus-sg | Egress | All | 0-65535 | 0.0.0.0/0 | Outbound traffic |
| grafana-sg | Ingress | TCP | 22 | 0.0.0.0/0* | SSH (restrict in production) |
| grafana-sg | Ingress | TCP | 3000 | 0.0.0.0/0* | Grafana UI |
| grafana-sg | Egress | All | 0-65535 | 0.0.0.0/0 | Outbound traffic |
- Note: Restrict 0.0.0.0/0 for ports 22, 9090, 3000 to specific IPs in production.

## Prerequisites

- AWS Account: IAM access keys with EC2, RDS, ALB, VPC, S3 permissions.
- Terraform: Version ~> 5.0.
- Ansible: Install via pip install ansible and ansible-galaxy collection install community.docker.
- Jenkins: With Git, Terraform, Ansible plugins.
- AWS CLI: Configured with credentials.
- SSH Key: Stored at keys/my-key.pem.
- S3 Bucket: my-state-file-terraform-bucket in us-east-1.

## Setup Instructions

1. **Clone Repository**: Clone the repository and navigate to the project directory.
2. **Configure Terraform**: Create a terraform.tfvars file in the terraform directory with:
    - MYSQL_USER = "root"
    - MYSQL_PASSWORD = "YUSSUFyasser"
    - MYSQL_DB = "todos"
    - ssh_private_key_path = "keys/my-key.pem"
3. **Set Up S3 Backend**: Create an S3 bucket named my-state-file-terraform-bucket in us-east-1 via the AWS Console to store Terraform state.
4. **Set Up Jenkins**: Install Jenkins with Git, Terraform, and Ansible plugins. Add AWS credentials in Credentials > Global. Create a pipeline using the Jenkinsfile.
5. **Run Jenkins Pipeline**: Push code to GitHub. Trigger the pipeline, which:
    - Executes generate_inventory.sh to create Ansible inventory.
    - Executes generate_prometheus_config.sh to configure Prometheus.
    - Applies Terraform to provision infrastructure.
    - Runs Ansible playbooks for EC2 and monitoring setup.
    
6. **Access Application**: Retrieve the ALB DNS name from Terraform outputs in the terraform directory. Access the app at http://<alb-dns-name>.
7. **Access Monitoring**:
    - Grafana: http://<grafana-ec2-ip>:3000 (admin/admin)
    - Prometheus: http://<prometheus-ec2-ip>:9090

## Key Components

### EC2 Instances

Four EC2 instances run in public subnets, using Amazon Linux 2 (t2.micro):

- **Web Servers (web0, web1)**:
    - Host the Dockerized todo app, configured by Ansible.
    - Subnets: us-east-1a (10.0.0.0/24), us-east-1b (10.0.2.0/24).
    - Security Group: Allows HTTP (80) from ALB, SSH (22), Node Exporter (9100).
    - Depend on RDS for database connectivity.
    - Public IPs enabled, accessed via SSH key vockey.
- **Prometheus Server**:
    - Runs Prometheus for metric collection.
    - Subnet: us-east-1c (10.0.3.0/24).
    - Security Group: Allows Prometheus UI (9090), SSH (22).
- **Grafana Server**:
    - Runs Grafana for metric visualization.
    - Subnet: us-east-1c (10.0.3.0/24).
    - Security Group: Allows Grafana UI (3000), SSH (22).

### Application Load Balancer (ALB)

- Type: Application Load Balancer.
- Subnet: Public subnet (10.0.0.0/24).
- Security Group: Permits HTTP (80) from any IP, all outbound traffic.
- Target Group: Routes traffic to web EC2 instances on port 80.
- Features: Ensures high availability, health monitoring, and scalable traffic distribution via a single DNS endpoint.

### RDS

- Engine: MySQL 5.7.
- Instance: db.t3.micro with 20GB gp2 storage.
- Subnet Group: Spans public and private subnets for resilience.
- Security Group: Allows MySQL (3306) from web EC2 instances.
- Credentials: Configured via Terraform variables (MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB=todos).
- Purpose: Provides persistent storage for the todo app.

### Docker

- Image: mahmoudmabdelhamid/getting-started.
- Port Mapping: Container port 3000 maps to host port 80.
- Environment Variables:
    - MYSQL_HOST: RDS endpoint.
    - MYSQL_USER: Database user.
    - MYSQL_PASSWORD: Database password.
    - MYSQL_DB: todos.
- Deployed on web EC2 instances via Ansible.

### Terraform State Management

- Backend: S3 bucket my-state-file-terraform-bucket in us-east-1.
- State File: statefile.tfstate.
- Locking: Enabled for team collaboration.
- Setup: Create the bucket in the AWS Console before running Terraform.

### Ansible Playbooks

- **EC2 Setup**: Installs Docker, MariaDB client, and deploys the app on web instances.
- **Node Exporter**: Installs Node Exporter on web instances for metrics.
- **Prometheus**: Configures Prometheus on the Prometheus instance.
- **Grafana**: Sets up Grafana with a Prometheus datasource.

### Scripts

- **generate_inventory.sh**: Creates Ansible inventory (inventory.ini) using Terraform outputs for web, Prometheus, and Grafana instances. Updates RDS endpoint in Ansible variables.
- **generate_prometheus_config.sh**: Generates Prometheus configuration (prometheus.yml) with private IPs of web instances for Node Exporter scraping.

### Jenkins Pipeline

The Jenkins pipeline automates:

- Script execution for inventory and Prometheus setup.
- Terraform infrastructure provisioning.
- Ansible configuration of EC2 and monitoring services. Defined in Jenkinsfile, it uses AWS credentials for access.
    
    ![Image](https://github.com/user-attachments/assets/cb73c3f8-2b06-48a0-9c7c-787246025d1e)
    

### Monitoring

- **Prometheus**: Collects metrics from web0 and web1 via Node Exporter.
    
    ![Image](https://github.com/user-attachments/assets/5c0cbf4e-08ca-40a0-84a0-6f456b331589)
    
- **Grafana**: Visualizes metrics collected by Prometheus.
    
    ![Image](https://github.com/user-attachments/assets/177c7beb-60ab-4984-82a5-dea82c3375e0)
    

### **📡 App Overview**

![Image](https://github.com/user-attachments/assets/dc8d3b5a-976f-4704-bfd9-9ab8e64360d3)
