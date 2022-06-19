pipeline{
    agent any
    tools {
        terraform 'terraform'
    }   
   parameters {
        string(name: 'environment', defaultValue: 'default', description: 'Workspace/environment file to use for deployment')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')
        // destroy parameter is false because you have to delete the ingress (see README.md) before doing a terraform destroy or it will leave some resources undestroyed.
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    
    stages {
        
           stage('Git Checkout') {
            steps{
                git branch: 'main', credentialsId: 'Github-cred', url: 'https://github.com/PL-SoftwareEngineering2022/terr-ans-eks.git'
            }
        }

        stage('TerraformInit'){
            steps {
                //  dir('jenkins-terraform-pipeline/ec2_pipeline/'){
                // withAWS(credentials: 'Aws-cred', profile: 'default', region: 'us-west-1', roleAccount: '137236605350') {
                // // some block}
                sh 'terraform init -input=false'
                    // or simply: sh 'terraform init'
                }
        }
 
        stage('TerraformFormat'){
            steps {
                //  dir('jenkins-terraform-pipeline/ec2_pipeline/'){
                    sh "terraform fmt"
            }
        }

        stage('TerraformValidate'){
            steps {
                //  dir('jenkins-terraform-pipeline/ec2_pipeline/'){
                    sh "terraform validate"
                }
            }

        stage('Plan') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            
            steps {
               // sh 'terraform workspace select ${environment} || terraform workspace new ${environment}'
                sh "terraform plan -input=false -out tfplan "
                // sh 'terraform show -no-color tfplan > tfplan.txt' - will otput the plan to tfplan.txt
            }
        }

        stage('Approval') {
           when {
               not {
                   equals expected: true, actual: params.autoApprove
               }
               not {
                    equals expected: true, actual: params.destroy
                }
           }
                   
           steps {
               script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
        }

        stage('Apply') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            
            steps {
                sh "terraform apply -input=false tfplan"
            }
        }
        
        stage('Destroy') {
            when {
                equals expected: true, actual: params.destroy
            }
        
        steps {
           sh "terraform destroy --auto-approve"
        }
    }
    }
}