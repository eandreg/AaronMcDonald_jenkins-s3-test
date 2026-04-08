pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "${env.WORKSPACE}/terraform-bin:${env.WORKSPACE}/aws-cli-bin:${env.PATH}"
    }
    stages {
        stage('Install & Setup Tools') {
            steps {
                sh '''
                set -euo pipefail

                echo "=== Cleaning previous Terraform & AWS CLI install ==="
                rm -rf terraform* terraform-bin awscliv2.zip aws aws-cli aws-cli-bin

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

                # --- Terraform 1.14.8 ---
                echo "Installing Terraform 1.14.8 locally..."
                TF_VERSION="1.14.8"
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"
                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "✅ Terraform installed to ${WORKSPACE}/terraform-bin/terraform"
                else
                    echo "❌ Terraform download failed."
                    exit 1
                fi

                # --- AWS CLI v2 (FINAL FIXED INSTALL) ---
                echo "Installing AWS CLI v2 locally..."
                AWS_ZIP="awscliv2.zip"
                curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${AWS_ZIP}"
                if [ -s "${AWS_ZIP}" ]; then
                    unzip -q -o "${AWS_ZIP}"
                    mkdir -p "${WORKSPACE}/aws-cli-bin"
                    # CORRECTED: -b points to the DIRECTORY (not the file)
                    ./aws/install -i "${WORKSPACE}/aws-cli" -b "${WORKSPACE}/aws-cli-bin" --update
                    chmod +x "${WORKSPACE}/aws-cli-bin/aws"
                    echo "✅ AWS CLI v2 installed to ${WORKSPACE}/aws-cli-bin/aws"
                    ls -la "${WORKSPACE}/aws-cli-bin/aws" || true
                else
                    echo "❌ AWS CLI download failed."
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
                    set -euo pipefail

                    echo "=== Terraform Operations ==="
                    terraform version
                    aws --version

                    terraform init
                    terraform validate

                    echo "Running terraform fmt -recursive (auto-fixes formatting)..."
                    terraform fmt -recursive

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

                            echo "=== Running Aggressive Cleanup for ALL jenkins-bucket-andre-class7* buckets ==="
                            aws s3 ls | awk '{print $3}' | grep '^jenkins-bucket-andre-class7' | while read -r bucket; do
                                echo "→ Force-deleting orphaned bucket: $bucket"
                                aws s3 rm s3://$bucket --recursive --force || true
                                aws s3api delete-bucket --bucket "$bucket" || true
                            done

                            echo "=== Verification: Checking for any remaining test buckets ==="
                            REMAINING=$(aws s3 ls | awk '{print $3}' | grep '^jenkins-bucket-andre-class7' | wc -l)
                            if [ "$REMAINING" -eq 0 ]; then
                                echo "✅ ALL test S3 buckets successfully deleted from AWS console!"
                            else
                                echo "⚠️  Some buckets still remain. Check AWS console manually."
                                exit 1
                            fi
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