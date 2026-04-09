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
                    
                    echo "=== Step 1: Formatting and Validation ==="
                    terraform fmt -recursive
                    terraform validate
                    
                    echo "=== Step 2: Initializing Backend ==="
                    # -reconfigure handles the switch between remote and local state
                    terraform init -reconfigure
                    
                    echo "=== Step 3: Generating Plan ==="
                    terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Apply') {
            steps {
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
