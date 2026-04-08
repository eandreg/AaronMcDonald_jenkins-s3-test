pipeline {
    agent any

    environment {
        TF_VERSION = "1.14.8"
        TF_BIN_DIR = "${WORKSPACE}/terraform-bin"
    }

    stages {
        stage('Install & Setup Tools') {
            steps {
                sh '''
                set -euo pipefail

                echo "=== Cleaning previous Terraform install ==="
                rm -rf terraform* "${TF_BIN_DIR}"

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

                # --- Terraform (pinned version) ---
                echo "Installing Terraform ${TF_VERSION} locally..."
                TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
                curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP}" -o "${TF_ZIP}"

                if [ -s "${TF_ZIP}" ]; then
                    unzip -q -o "${TF_ZIP}"
                    mkdir -p "${TF_BIN_DIR}"
                    mv terraform "${TF_BIN_DIR}/"
                    chmod +x "${TF_BIN_DIR}/terraform"
                    echo "✅ Terraform ${TF_VERSION} installed to ${TF_BIN_DIR}"
                else
                    echo "❌ Terraform download failed."
                    exit 1
                fi
                '''
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
                    withEnv(["PATH+TERRAFORM=${TF_BIN_DIR}"]) {
                        sh '''
                        set -euo pipefail
                        terraform version
                        terraform init
                        terraform validate
                        terraform fmt -recursive -check=true   # fail build if formatting is bad
                        terraform plan -out=tfplan
                        '''
                    }
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
                    withEnv(["PATH+TERRAFORM=${TF_BIN_DIR}"]) {
                        sh 'terraform apply tfplan'
                    }
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
                            withEnv(["PATH+TERRAFORM=${TF_BIN_DIR}"]) {
                                sh 'terraform destroy -auto-approve'
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        success { echo '✅ Terraform deployment completed successfully!' }
        failure { echo '❌ Terraform deployment failed!' }
        always {
            // Optional: clean up plan file
            sh 'rm -f tfplan'
        }
    }
}
/*
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
        rm -rf terraform* terraform-bin .terraform .terraform.lock.hcl   # ← ADD THIS

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
}*/
/*        stage('Install & Setup Tools') {
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
}*/
