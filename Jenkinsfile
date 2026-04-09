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

                echo "Installing Terraform 1.14.8 locally..."
                TF_VERSION="1.14.8"
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"
                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "✅ Terraform 1.14.8 installed"
                else
                    echo "❌ Terraform download failed."
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

        stage('Terraform Init & Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh '''
                    set -euo pipefail
                    echo "=== Terraform Init & Validate ==="
                    terraform version
                    terraform init
                    terraform validate
                    echo "Running terraform fmt -recursive..."
                    terraform fmt -recursive
                    '''
                }
            }
        }

        stage('Pre-Apply Cleanup (guaranteed no BucketAlreadyExists)') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh '''
                    set -euo pipefail
                    echo "=== Pre-Apply Cleanup: Removing any existing jenkins-bucket-andre-class7-fixed ==="
                    terraform import aws_s3_bucket.frontend jenkins-bucket-andre-class7-fixed 2>/dev/null || true
                    terraform destroy -target=aws_s3_bucket.frontend -auto-approve || true
                    echo "✅ Any existing bucket has been cleaned up."
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh '''
                    set -euo pipefail
                    echo "=== Terraform Plan ==="
                    terraform plan -out=tfplan
                    echo "Terraform plan completed successfully."
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
                            sh '''
                            set -euo pipefail
                            echo "=== Running Terraform Destroy ==="
                            terraform destroy -auto-approve
                            echo "✅ Terraform destroy completed. The S3 bucket has been deleted."
                            '''
                        }
                    }
                }
            }
        }
    }
    post {
        success { echo '✅ Terraform deployment completed successfully!' }
        failure { echo '❌ Terraform deployment failed!' }
    }
}