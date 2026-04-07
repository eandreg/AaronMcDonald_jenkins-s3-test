pipeline {
    agent any
   
    environment {
        // Renamed to AWS_DEFAULT_REGION so Terraform/AWS CLI detect it automatically
        AWS_DEFAULT_REGION = 'us-east-1' 
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                checkout scm
                // Standard check to ensure tools are available on the agent
                sh 'terraform version'
                sh 'aws --version'
            }
        }

        stage('Terraform Operations') {
            steps {
                // Wrapping all AWS-dependent stages in one block to keep code DRY
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'jenkinsTest' 
                ]]) {
                    sh '''
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
                    // Fixed: 'terraform apply' with a plan file does not use -auto-approve
                    sh 'terraform apply tfplan'
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
            // Warning: Since you are using local state, do NOT use cleanWs() here 
            // or you will lose your .tfstate file.
        }
        failure {
            echo 'Terraform deployment failed!'
        }
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