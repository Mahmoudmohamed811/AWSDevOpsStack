pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_SESSION_TOKEN     = credentials('aws_session_token')

        TF_VAR_access_key     = "${AWS_ACCESS_KEY_ID}"
        TF_VAR_secret_key     = "${AWS_SECRET_ACCESS_KEY}"
        TF_VAR_session_token  = "${AWS_SESSION_TOKEN}"
    }

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Mahmoudmohamed811/AWSDevOpsStack.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('generate prometheus config'){
            steps{
                dir('scripts') {
                    sh '''
              chmod +x generate_prometheus_config.sh
              ./generate_prometheus_config.sh
            '''
                }
            }
        }

        stage('Prepare Ansible Inventory and Keys') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-private-key', variable: 'SSH_KEY')]) {
                    dir('playbooks') {
                        sh '''
              mkdir -p keys
              cp "$SSH_KEY" keys/my-key.pem
              chmod 400 keys/my-key.pem

              chmod +x ../scripts/generate_inventory.sh
              ../scripts/generate_inventory.sh
            '''
                    }
                }
            }
        }

        stage('Run Ansible Playbooks') {
            steps {
                dir('playbooks') {
                    sh '''
            ansible-playbook -i inventory.ini playbook.yml --ssh-extra-args='-o StrictHostKeyChecking=no'
            ansible-playbook -i inventory.ini playbook2.yml --ssh-extra-args='-o StrictHostKeyChecking=no'
            ansible-playbook -i inventory.ini playbook3.yml --ssh-extra-args='-o StrictHostKeyChecking=no'
          '''
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed!'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}
