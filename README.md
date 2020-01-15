# pre-commit-hooks-terraform

This project contains some useful hooks for https://pre-commit.com.

## Use-Case: Terraform Input Variables to Jenkins Pipeline Parameters

The `terraform_inputs_jenkins_pipeline_params` hook supports the definition of a [Declarative Jenkins Pipeline](https://jenkins.io/doc/book/pipeline/syntax/#declarative-pipeline)'s [parameters](https://jenkins.io/doc/book/pipeline/syntax/#parameters) from your [Terraform Input Variables](https://www.terraform.io/intro/getting-started/variables.html).

*Note:* Requires [segmentio/terraform-docs](https://github.com/segmentio/terraform-docs) >= v0.8.0.

### Sample Usage

#### 1. Add the hook to your .pre-commit-config.yaml

```
repos:
- repo: git://github.com/getcloudnative/pre-commit-hooks
  rev: v1.4.0
  hooks:
    - id: terraform_inputs_jenkins_pipeline_params
```

#### 2. Add placeholders to your project's Jenkinsfile

The `terraform_inputs_jenkins_pipeline_params` hook places the Jenkins Pipeline parameters inside the following `BEGINNING OF … HOOK` and `END OF … HOOK` placeholders in your project's `Jenkinsfile`:

```
pipeline {
  agent any

  parameters {
    string(name: 'AWS_ACCESS_KEY_ID',     description: 'The AWS Access Key ID to use.')
    string(name: 'AWS_SECRET_ACCESS_KEY', description: 'The AWS Secret Access Key to use.')
    string(name: 'AWS_DEFAULT_REGION',    description: 'The AWS Region to use for deployment.')

    // BEGINNING OF JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS PRE-COMMIT HOOK
    // END OF JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS PRE-COMMIT HOOK
  }
  ...
}
```

## Use-Case: Terraform Input Variables from Jenkins Pipeline Parameters

The `terraform_inputs_jenkins_pipeline_params` hook supports the creation of a [terraform.tfvars.json](https://www.terraform.io/intro/getting-started/variables.html#from-a-file) based on your [Terraform Input Variables](https://www.terraform.io/intro/getting-started/variables.html), with values provided by the Jenkins Pipeline parameters' arguments.

*Note:* Requires [segmentio/terraform-docs](https://github.com/segmentio/terraform-docs) >= v0.8.0.

### Sample Usage

#### 1. Add the hook to your .pre-commit-config.yaml

```
repos:
- repo: git://github.com/getcloudnative/pre-commit-hooks
  rev: v1.4.0
  hooks:
    - id: terraform_inputs_jenkins_pipeline_params
```

#### 2. Add placeholders to your project's Jenkinsfile

The `terraform_inputs_jenkins_pipeline_params` hook places the Jenkins Pipeline parameters inside the following `BEGINNING OF … HOOK` and `END OF … HOOK` placeholders in your project's `Jenkinsfile`:

```
pipeline {
  agent any

  parameters {
    ...
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
```

## Testing

You can test the behavior of the `terraform_inputs_jenkins_pipeline_params` hook by executing the following commands, where `TERRAFORM_MODULE_PATH` is either a path to a Terraform module directory, or contains a sequence of files containing Terraform `variable` definitions. The results can then be seen in the project's `Jenkinsfile`.

```
git clone https://github.com/getcloudnative/pre-commit-hooks-terraform.git
pre-commit try-repo ./pre-commit-hooks-terraform terraform_inputs_jenkins_pipeline_params --files $TERRAFORM_MODULE_PATH
```
