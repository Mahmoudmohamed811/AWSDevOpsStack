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
docker run -d -p 80:3000 --name getting-started \
  -e MYSQL_HOST="${MYSQL_HOST}" \
  -e MYSQL_USER="${MYSQL_USER}" \
  -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
  -e MYSQL_DB="${MYSQL_DB}" \
  mahmoudmabdelhamid/getting-started