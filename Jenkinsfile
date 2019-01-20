pipeline {
    parameters {
        string(name:'PROJ_NAME', defaultValue:'macscampingarea', description: 'The project being deployed')
        string(name:'ENV_NAME', defaultValue:'dev', description:'The environment being deployed')
        string(name:'LOCATION', defaultValue:'eastus2', description:'The default region to deploy to')
    }
    agent any
        stages {
            stage('bootstrap'){
                steps {
                    checkout(
                        [
                            $class: 'GitSCM', 
                            branches: [[name: '*/master']], 
                            doGenerateSubmoduleConfigurations: false, 
                            extensions: [[$class: 'WipeWorkspace']], 
                            submoduleCfg: [], 
                            userRemoteConfigs: [[
                                credentialsId: 'JenkinsPAT', 
                                url: 'https://mrdelirium@dev.azure.com/mrdelirium/MacsCampingArea/_git/Terraform'
                            ]]
                        ]
                    )
                    withCredentials([azureServicePrincipal('JenkinsAzBuilder')]) {
                        sh label: 'Setup Build Dependencies', 
                        script: 'pwsh bootstrap/setup-infrastructure.ps1 -ProjectName ${PROJ_NAME} -EnvironmentName ${ENV_NAME} -Location ${LOCATION}'
                    }
                    sh (label: 'Install Linuxbrew',
                    script: '''
                        wget -O - https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh | bash
                        brew install terragrunt
                    ''')
                }
            }
            stage('terraform init'){
                steps {
                    withCredentials([azureServicePrincipal(
                        clientIdVariable: 'ARM_CLIENT_ID', 
                        clientSecretVariable: 'ARM_CLIENT_SECRET', 
                        credentialsId: 'JenkinsAzBuilder', 
                        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID', 
                        tenantIdVariable: 'ARM_TENANT_ID'), azureStorage('DevOpsStorage')]) {
                        withEnv(['TF_IN_AUTOMATION=TRUE']) {
                            sh label: 'Intialize Terraform Code',
                            script: 'terraform init -input=false'
                        }
                    }
                }
            }
            stage('terraform plan'){
                steps {
                    withEnv(['TF_IN_AUTOMATION=TRUE']) {
                        withCredentials([azureServicePrincipal(clientIdVariable: 'ARM_CLIENT_ID', clientSecretVariable: 'ARM_CLIENT_SECRET', credentialsId: 'JenkinsAzBuilder', subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID', tenantIdVariable: 'ARM_TENANT_ID'), azureStorage('DevOpsStorage')]) {
                            sh label: 'Running Terraform Plan',
                            script: 'terraform plan -o tfplan -input=false'
                        }
                    }
                }
            }
            stage('terraform apply'){
                steps {
                    withEnv(['TF_IN_AUTOMATION=TRUE']) {
                        withCredentials([azureServicePrincipal(clientIdVariable: 'ARM_CLIENT_ID', clientSecretVariable: 'ARM_CLIENT_SECRET', credentialsId: 'JenkinsAzBuilder', subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID', tenantIdVariable: 'ARM_TENANT_ID'), azureStorage('DevOpsStorage')]) {
                            sh label: 'Applying Terraform Configuration',
                            script: 'terraform apply tfplan -input=false'
                        }
                    }
                }
            }
        }
}