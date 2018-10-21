#!/usr/bin/env groovy

pipeline {
  agent any

  parameters {
    string(name: 'AWS_ACCESS_KEY_ID',     description: 'The AWS Access Key ID to use.')
    string(name: 'AWS_SECRET_ACCESS_KEY', description: 'The AWS Secret Access Key to use.')
    string(name: 'AWS_DEFAULT_REGION',    description: 'The AWS Region to use for deployment.')

    // BEGINNING OF JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS PRE-COMMIT HOOK
    // END OF JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS PRE-COMMIT HOOK
  }

  stages {
    stage('Init') {
      steps {
        echo "Create the stack's terraform.tfvars.json."
        script {
          // BEGINNING OF JENKINS-PIPELINE-PARAMS-TO-TERRAFORM-TFVARS-JSON PRE-COMMIT HOOK
          // END OF JENKINS-PIPELINE-PARAMS-TO-TERRAFORM-TFVARS-JSON PRE-COMMIT HOOK
        }
      }
    }
  }
}
