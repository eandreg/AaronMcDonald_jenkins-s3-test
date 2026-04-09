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

    options {
        timeout(time: 30, unit: 'MINUTES')  // Prevent hung input steps from blocking executor indefinitely
    }

    environment {
        AWS_DEFAULT_REGION   = 'us-east-1'
        PATH                 = "${env.WORKSPACE}/terraform-bin:${env.PATH}"
        TF_VERSION           = "1.9.5"
        CHECKPOINT_DISABLE   = "1"  // ✅ FIX: Suppresses the spurious "latest version is 1.14.8" warning from HashiCorp's checkpoint service
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

                echo "Installing Terraform ${TF_VERSION} locally..."
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                TF_SHA_FILE="terraform_${TF_VERSION}_SHA256SUMS"

                curl -sSf "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"
                curl -sSf "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_SHA_FILE}" -o "${TF_SHA_FILE}"

                echo "Verifying SHA256 checksum..."
                grep "${TF_ZIP}" "${TF_SHA_FILE}" | sha256sum -c -
                echo "✅ Checksum verified."

                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${WORKSPACE}/terraform-bin"
                    mv terraform "${WORKSPACE}/terraform-bin/"
                    chmod +x "${WORKSPACE}/terraform-bin/terraform"
                    echo "✅ Terraform ${TF_VERSION} installed"
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

                    # ✅ FIX: Use -upgrade to force a fresh provider download on every run.
                    # The previous failure ("Plugin did not respond") was caused by the AWS provider
                    # being loaded from a stale/corrupt cache. -upgrade ensures a clean provider
                    # binary is always used, eliminating gRPC crash and architecture mismatch issues.
                    terraform init -upgrade

                    terraform validate

                    echo "Running terraform fmt -check -recursive..."
                    terraform fmt -check -recursive
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
        success {
            echo '✅ Terraform deployment completed successfully!'
        }
        failure {
            echo '❌ Terraform deployment failed!'
        }
        cleanup {
            // Always clean up ephemeral artifacts from the workspace after every run
            sh '''
            echo "=== Post-run Cleanup ==="
            rm -f tfplan
            rm -f terraform_*.zip terraform_*_SHA256SUMS
            rm -rf terraform-bin
            echo "✅ Workspace cleaned."
            '''
        }
    }
}
