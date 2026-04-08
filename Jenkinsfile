pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "${env.WORKSPACE}/terraform-bin:${env.PATH}"
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                sh '''
                set -euo pipefail

                echo "=== Cleaning previous Terraform install ==="
                rm -rf terraform* terraform-bin

                # --- Unzip (if missing) ---
                if ! command -v unzip &> /dev/null; then
                    echo "unzip not found. Attempting install..."
                    if command -v apt-get &> /dev/null; then
                        apt-get update -qq && apt-get install -y unzip || echo "Warning: Could not install unzip"
                    elif command -v yum &> /dev/null; then
                        yum install -y unzip || echo "Warning: Could not install unzip"
                    else
                        echo "Warning: unzip missing"
                    fi
                else
                    echo "unzip already available."
                fi

                # --- Terraform (latest stable) ---
                echo "Installing Terraform locally..."
                TF_VERSION="1.14.8"
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"

                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "Terraform ${TF_VERSION} installed to ${WORKSPACE}/terraform-bin"
                else
                    echo "Error: Terraform download failed."
                    exit 1
                fi
                '''
                sh 'terraform version'
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
                    terraform init
                    terraform validate
                    terraform fmt -recursive
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
                    sh 'terraform apply tfplan'
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
                            sh 'terraform destroy -auto-approve'
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
/*pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "${env.WORKSPACE}/terraform-bin:${env.WORKSPACE}/aws-bin:${env.PATH}"
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                sh '''
                set -euo pipefail

                echo "=== Cleaning previous tool installs (critical for WSL2) ==="
                rm -rf aws-cli aws-bin awscliv2.zip terraform* 

                # --- Unzip ---
                if ! command -v unzip &> /dev/null; then
                    echo "unzip not found. Attempting install..."
                    if command -v apt-get &> /dev/null; then
                        apt-get update -qq && apt-get install -y unzip || echo "Warning: Could not install unzip"
                    elif command -v yum &> /dev/null; then
                        yum install -y unzip || echo "Warning: Could not install unzip"
                    else
                        echo "Warning: unzip missing"
                    fi
                else
                    echo "unzip already available."
                fi

                # --- AWS CLI v2 - FORCE CLEAN INSTALL EVERY TIME (fixes WSL2 corruption) ---
                echo "Installing fresh AWS CLI v2..."
                curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

                if [ -s "awscliv2.zip" ]; then
                    unzip -q -o awscliv2.zip
                    ./aws/install -i $(pwd)/aws-cli -b $(pwd)/aws-bin --update
                    echo "AWS CLI installed fresh to $(pwd)/aws-bin"
                else
                    echo "Error: AWS CLI download failed."
                    exit 1
                fi

                # --- Terraform (latest stable) ---
                echo "Installing Terraform locally..."
                TF_VERSION="1.14.8"
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"

                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "Terraform ${TF_VERSION} installed to ${WORKSPACE}/terraform-bin"
                else
                    echo "Error: Terraform download failed."
                    exit 1
                fi
                '''
                sh 'terraform version'
                sh 'aws --version'
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
                    aws sts get-caller-identity
                    terraform init
                    terraform validate
                    terraform fmt -recursive
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
                    sh 'terraform apply tfplan'
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
                            sh 'terraform destroy -auto-approve'
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
}*/
/*pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "${env.WORKSPACE}/terraform-bin:${env.WORKSPACE}/aws-bin:${env.PATH}"
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                sh '''
                set -euo pipefail

                # --- Unzip (required for both installs) ---
                if ! command -v unzip &> /dev/null; then
                    echo "unzip not found. Attempting install (no sudo available on this agent)..."
                    if command -v apt-get &> /dev/null; then
                        apt-get update -qq && apt-get install -y unzip || echo "Warning: Could not install unzip (no sudo/permissions)"
                    elif command -v yum &> /dev/null; then
                        yum install -y unzip || echo "Warning: Could not install unzip"
                    else
                        echo "Warning: unzip missing and no package manager found."
                    fi
                else
                    echo "unzip already available."
                fi

                # --- AWS CLI v2 (local install) ---
                if ! command -v aws &> /dev/null; then
                    echo "AWS CLI not found. Downloading..."
                    for i in {1..3}; do
                        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && break || sleep 5
                    done

                    if [ -s "awscliv2.zip" ]; then
                        unzip -q -o awscliv2.zip
                        ./aws/install -i $(pwd)/aws-cli -b $(pwd)/aws-bin --update
                        echo "AWS CLI installed to $(pwd)/aws-bin"
                    else
                        echo "Error: awscliv2.zip is empty or failed to download."
                        exit 1
                    fi
                else
                    echo "AWS CLI already exists on system."
                fi

                # --- Terraform (local install - latest version) ---
                echo "Installing Terraform locally..."
                TF_VERSION="1.14.8"   # Latest version reported by your agent
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"

                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "Terraform ${TF_VERSION} installed to ${WORKSPACE}/terraform-bin"
                else
                    echo "Error: Terraform download failed."
                    exit 1
                fi
                '''
                sh 'terraform version'
                sh 'aws --version'
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
                    aws sts get-caller-identity
                    terraform init
                    terraform validate
                    terraform fmt -recursive          # Auto-formats files (no longer fails the build)
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
                    sh 'terraform apply tfplan'
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
                            sh 'terraform destroy -auto-approve'
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
}*/
/*pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "${env.WORKSPACE}/terraform-bin:${env.WORKSPACE}/aws-bin:${env.PATH}"
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                sh '''
                set -euo pipefail

                # --- Unzip (required for both installs) ---
                if ! command -v unzip &> /dev/null; then
                    echo "unzip not found. Attempting install (no sudo available on this agent)..."
                    if command -v apt-get &> /dev/null; then
                        apt-get update -qq && apt-get install -y unzip || echo "Warning: Could not install unzip (no sudo/permissions)"
                    elif command -v yum &> /dev/null; then
                        yum install -y unzip || echo "Warning: Could not install unzip"
                    else
                        echo "Warning: unzip missing and no package manager found."
                    fi
                else
                    echo "unzip already available."
                fi

                # --- AWS CLI v2 (local install) ---
                if ! command -v aws &> /dev/null; then
                    echo "AWS CLI not found. Downloading..."
                    for i in {1..3}; do
                        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && break || sleep 5
                    done

                    if [ -s "awscliv2.zip" ]; then
                        unzip -q -o awscliv2.zip
                        ./aws/install -i $(pwd)/aws-cli -b $(pwd)/aws-bin --update
                        echo "AWS CLI installed to $(pwd)/aws-bin"
                    else
                        echo "Error: awscliv2.zip is empty or failed to download."
                        exit 1
                    fi
                else
                    echo "AWS CLI already exists on system."
                fi

                # --- Terraform (local install - fully self-contained) ---
                echo "Installing Terraform locally..."
                TF_VERSION="1.10.5"   # ← Update this if you want a newer version
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"

                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "Terraform ${TF_VERSION} installed to ${WORKSPACE}/terraform-bin"
                else
                    echo "Error: Terraform download failed."
                    exit 1
                fi
                '''
                sh 'terraform version'
                sh 'aws --version'
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
                    aws sts get-caller-identity
                    terraform init
                    terraform validate
                    terraform fmt -check -recursive || (echo "❌ Terraform files are not formatted! Please run '\''terraform fmt'\'' locally." && exit 1)
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
                    sh 'terraform apply tfplan'
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
                            sh 'terraform destroy -auto-approve'
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
}*/
/*pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "${env.WORKSPACE}/aws-bin:${env.PATH}"
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                script {
                    def tfHome = tool name: 'terraform-latest'
                    env.PATH = "${tfHome}:${env.PATH}"
                }
                sh '''
                # Ensure unzip is available (required for AWS CLI installation)
                if ! command -v unzip &> /dev/null; then
                    echo "unzip not found. Installing..."
                    if [ -f /etc/debian_version ]; then
                        sudo apt-get update -qq && sudo apt-get install -y unzip
                    elif [ -f /etc/redhat-release ]; then
                        sudo yum install -y unzip
                    else
                        echo "Warning: Could not auto-install unzip. Build may fail if unzip is missing."
                    fi
                fi

                if ! command -v aws &> /dev/null; then
                    echo "AWS CLI not found. Downloading..."
                    
                    # Retry the download up to 3 times if it fails
                    for i in {1..3}; do
                        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && break || sleep 5
                    done

                    # Verify the file exists and is not empty before unzipping
                    if [ -s "awscliv2.zip" ]; then
                        unzip -q -o awscliv2.zip
                        ./aws/install -i $(pwd)/aws-cli -b $(pwd)/aws-bin --update
                        echo "AWS CLI installed to $(pwd)/aws-bin"
                    else
                        echo "Error: awscliv2.zip is empty or failed to download."
                        exit 1
                    fi
                else
                    echo "AWS CLI already exists on system."
                fi
                '''
                sh 'terraform version'
                sh 'aws --version'
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
                    aws sts get-caller-identity
                    terraform init
                    terraform validate
                    terraform fmt -check -recursive || (echo "❌ Terraform files are not formatted! Please run '\''terraform fmt'\'' locally." && exit 1)
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
                    sh 'terraform apply tfplan'
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
                            sh 'terraform destroy -auto-approve'
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
}*/

/*pipeline {
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
                    echo "AWS CLI not found. Downloading..."
                    
                    # Retry the download up to 3 times if it fails
                    for i in {1..3}; do
                        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && break || sleep 5
                    done

                    # Verify the file exists and is not empty before unzipping
                    if [ -s "awscliv2.zip" ]; then
                        unzip -q -o awscliv2.zip
                        ./aws/install -i $(pwd)/aws-cli -b $(pwd)/aws-bin --update
                        echo "AWS CLI installed to $(pwd)/aws-bin"
                    else
                        echo "Error: awscliv2.zip is empty or failed to download."
                        exit 1
                    fi
                else
                    echo "AWS CLI already exists on system."
                fi
                '''
                sh 'terraform version'
                sh 'export PATH="$PATH:$(pwd)/aws-bin" && if [ -f "./aws-bin/aws" ]; then ./aws-bin/aws --version; else aws --version; fi'
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
                    terraform fmt -check -recursive || (echo "❌ Terraform files are not formatted! Please run 'terraform fmt' locally." && exit 1)
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
}*/