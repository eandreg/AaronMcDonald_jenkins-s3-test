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
                    echo "AWS CLI not found. Downloading portable version..."
                    # Download the CLI zip
                    curl "https://amazonaws.com" -o "awscliv2.zip"
                    # Unzip into the workspace (no root needed)
                    unzip -o awscliv2.zip
                    # Add the new AWS folder to the PATH for this session
                    export PATH="$PATH:$(pwd)/aws/dist"
                    echo "AWS CLI ready at: $(pwd)/aws/dist/aws"
                else
                    echo "AWS CLI is already installed."
                fi
                '''
                
                // Verify tools work in this environment
                sh 'terraform version'
                // We add the path again here to ensure 'sh' sees it
                sh 'PATH=$PATH:$(pwd)/aws/dist aws --version'
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Operations') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest' 
                ]]) {
                    sh '''
                    # Update PATH to find our portable AWS CLI
                    export PATH="$PATH:$(pwd)/aws/dist"
                    
                    echo "Verifying AWS Identity..."
                    aws sts get-caller-identity

                    echo "Initializing Terraform..."
                    terraform init

                    echo "Validating and Formatting..."
                    terraform validate
                    terraform fmt

                    echo "Generating Plan..."
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
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest'
                ]]) {
                    sh '''
                    export PATH="$PATH:$(pwd)/aws/dist"
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
                            sh '''
                            export PATH="$PATH:$(pwd)/aws/dist"
                            terraform destroy -auto-approve
                            '''
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
        AWS_REGION = 'us-east-1' 
    }
    stages {
        
        // AWS Credentials documentation: https://plugins.jenkins.io/aws-credentials/
        stage('Set AWS Credentials') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest' //this needs to be changed to match the ID of your AWS credentials in Jenkins
                ]]) {
                    sh '''
                    echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
                    aws sts get-caller-identity
                    '''
                }
            }
        }
        stage('Checkout Code') {
            steps {
                checkout scm 
            }
        }
  
        stage('Initialize Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest'
                ]]) {
                    sh '''

                    terraform init
                    '''
                }
            }
        }

        stage('Validate Terraform') {
            steps { 
                // terraform validate does NOT need credentials
                    sh '''

                    terraform validate
                    '''
            }
        }

            stage('Format Terraform') {
                steps {
                    // terraform fmt does NOT need credentials
                        sh '''

                        terraform fmt
                        '''
            }
        }
        stage('Plan Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest'
                ]]) {
                    sh '''

                    terraform plan -out=tfplan
                    '''
                }
            }
        }
        stage('Apply Terraform') {
            steps {
                input message: "Approve Terraform Apply?", ok: "Deploy"
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest'
                ]]) {
                    sh '''

                    terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Optional Destroy') {
            steps {
                script {
                    def destroyChoice = input(
                        message: 'Do you want to run terraform destroy?',
                        ok: 'Submit',
                        parameters: [
                            choice(
                                name: 'DESTROY',
                                choices: ['no', 'yes'],
                                description: 'Select yes to destroy resources'
                            )
                        ]
                    )
                    if (destroyChoice == 'yes') {
                    // Credentials are required to authenticate with AWS for resource removal
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                        sh 'terraform destroy -auto-approve'
                        }
                    } else {
                        echo "Skipping destroy"
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Terraform deployment completed successfully!'
        }
        failure {
            echo 'Terraform deployment failed!'
        }
    }
}*/

/*pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        // This is the folder where you just unzipped the terraform file
        TF_PATH = "/var/jenkins_home/workspace/jenkinsTest/Documents/TheoWAF"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Initialize Terraform') {
            steps {
                script {
                    withEnv(["PATH+TF=${TF_PATH}"]) {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'jenkinsTest'
                        ]]) {
                            sh 'terraform init'
                        }
                    }
                }
            }
        }

        stage('Validate & Format') {
            steps {
                script {
                    withEnv(["PATH+TF=${TF_PATH}"]) {
                        sh 'terraform validate'
                        sh 'terraform fmt'
                    }
                }
            }
        }

        stage('Plan Terraform') {
            steps {
                script {
                    withEnv(["PATH+TF=${TF_PATH}"]) {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'jenkinsTest'
                        ]]) {
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                }
            }
        }

        stage('Apply Terraform') {
            steps {
                input message: "Approve Terraform Apply?", ok: "Deploy"
                script {
                    withEnv(["PATH+TF=${TF_PATH}"]) {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'jenkinsTest'
                        ]]) {
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }
                }
            }
        }

        stage('Optional Destroy') {
            steps {
                script {
                    def destroyChoice = input(
                        message: 'Do you want to run terraform destroy?',
                        ok: 'Submit',
                        parameters: [
                            choice(name: 'DESTROY', choices: ['no', 'yes'], description: 'Select yes to destroy resources')
                        ]
                    )
                    if (destroyChoice == 'yes') {
                        withEnv(["PATH+TF=${TF_PATH}"]) {
                            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'jenkinsTest']]) {
                                sh 'terraform destroy -auto-approve'
                            }
                        }
                    } else {
                        echo "Skipping destroy"
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