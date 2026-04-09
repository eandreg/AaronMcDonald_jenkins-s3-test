/*pipeline {
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
}*/
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
                echo "=== Setting up Terraform ==="
                # We skip the unzip install attempt since your logs show it's already there
                
                TF_VERSION="1.14.8"
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                
                if [ ! -f "terraform-bin/terraform" ]; then
                    curl -s "https://hashicorp.com{TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "terraform-bin"
                    mv terraform terraform-bin/
                    chmod +x terraform-bin/terraform
                    rm "${TF_ZIP}"
                fi
                terraform version
                '''
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh '''
                    set -euo pipefail
                    echo "=== Initializing with Remote Backend ==="
                    # -reconfigure solves the "Backend configuration changed" error
                    terraform init -reconfigure
                    terraform validate
                    terraform fmt -recursive
                    terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Apply') {
            steps {
                // Human gate to prevent accidental deployments
                input message: "Approve Terraform Apply?", ok: "Deploy"
                
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                    sh 'terraform apply tfplan'
                }
            }
        }

        stage('Optional Destroy') {
            steps {
                script {
                    def destroyChoice = input(
                        message: 'Do you want to tear down the infrastructure?',
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
        success { echo '✅ Pipeline finished successfully!' }
        failure { echo '❌ Pipeline failed. Check the logs above for Terraform errors.' }
    }
}
