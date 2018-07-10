# pre-commit-hooks

Some useful hooks for https://pre-commit.com.

## Jenkins Pipeline Parameters from Terraform Input Variables

This pre-commit hook inserts [Terraform Input Variables](https://www.terraform.io/intro/getting-started/variables.html) into the [parameters directive](https://jenkins.io/doc/book/pipeline/syntax/#parameters) of a [Declarative Jenkins Pipeline](https://jenkins.io/doc/book/pipeline/syntax/#declarative-pipeline) in your project's `Jenkinsfile`. Additionally, it populates a JSON data structure to populate a `terraform.tfvars.json` file with the Jenkins Pipeline's parameter arguments. Requires [segmentio/terraform-docs](https://github.com/segmentio/terraform-docs).

### Sample Usage

#### 1. Add the hook to your .pre-commit-config.yaml

```
- repo: git://github.com/getcloudnative/pre-commit-hooks
  rev: v1.0.0
  hooks:
    - id: jenkins_pipeline_from_terraform_input_vars
```

#### 2. Integrate the supported placeholders into your Jenkinsfile

The pre-commit hook will place a representation of your Terraform input variables inside the following placeholders in your project root's `Jenkinsfile`:

```
pipeline {
  agent any

  parameters {
    // BEGINNING OF JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS PRE-COMMIT HOOK
    // END OF JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS PRE-COMMIT HOOK
  }

  stages {
    stage('Init') {
      steps {
        echo "Create terraform.tfvars.json from Jenkins Pipeline parameter arguments."
        script {
          // BEGINNING OF JENKINS-PIPELINE-PARAMS-TO-TERRAFORM-TFVARS-JSON PRE-COMMIT HOOK
          // END OF JENKINS-PIPELINE-PARAMS-TO-TERRAFORM-TFVARS-JSON PRE-COMMIT HOOK
        }
      }
    }
    ...
  }
}
```
