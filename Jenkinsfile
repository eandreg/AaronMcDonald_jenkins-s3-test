pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1' 
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                script {
                    def tfHome = tool name: 'terraform-latest'
                    env.PATH = "${tfHome}:${env.PATH}"
                }
                sh '''
                if ! command -v aws &> /dev/null; then
                    echo "AWS CLI not found. Downloading correct binary..."
                    # CRITICAL FIX (Version 6): Full official AWS CLI v2 Linux x86_64 URL
                    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    
                    unzip -q -o awscliv2.zip
                    
                    # Install locally in workspace to bypass any permission issues
                    ./aws/install -i $(pwd)/aws-cli -b $(pwd)/aws-bin --update
                    
                    echo "AWS CLI installed to $(pwd)/aws-bin"
                else
                    echo "AWS CLI already exists on system."
                fi
                '''
                sh 'terraform version'
                // Check if we use the local one we just built or the system one
                sh 'if [ -f "./aws-bin/aws" ]; then ./aws-bin/aws --version; else aws --version; fi'
            }
        }
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('Terraform Operations') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh '''
                    # Ensure the path includes our local install
                    export PATH="$PATH:$(pwd)/aws-bin"
                    aws sts get-caller-identity
                    terraform init
                    terraform validate
                    terraform fmt
                    terraform plan -out=tfplan
                    '''
                }
            }
        }
        stage('Approval') {
            steps {
                input message: "Approve Terraform Apply?", ok: "Deploy"
            }
        }
        stage('Apply Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh '''
                    export PATH="$PATH:$(pwd)/aws-bin"
                    terraform apply tfplan
                    '''
                }
            }
        }
        stage('Optional Destroy') {
            steps {
                script {
                    def destroyChoice = input(
                        message: 'Do you want to run terraform destroy?',
                        parameters: [choice(name: 'DESTROY', choices: ['no', 'yes'])]
                    )
                    if (destroyChoice == 'yes') {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                            sh 'export PATH="$PATH:$(pwd)/aws-bin" && terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
    post {
        success { echo 'Terraform deployment completed successfully!' }
        failure { echo 'Terraform deployment failed!' }
    }
}