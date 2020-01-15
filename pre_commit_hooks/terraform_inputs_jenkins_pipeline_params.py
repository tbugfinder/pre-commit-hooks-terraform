from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import argparse
import json
import re
import subprocess
import sys


JENKINSFILE_PARAMS_ID                   = 'JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS'
JENKINSFILE_PARAMS_PRE_COMMIT_HOOK_NAME = JENKINSFILE_PARAMS_ID + ' PRE-COMMIT HOOK'
JENKINSFILE_PARAMS_INDENT               = '    '

JENKINSFILE_TFVARS_JSON_ID                   = 'JENKINS-PIPELINE-PARAMS-TO-TERRAFORM-TFVARS-JSON'
JENKINSFILE_TFVARS_JSON_PRE_COMMIT_HOOK_NAME = JENKINSFILE_TFVARS_JSON_ID + ' PRE-COMMIT HOOK'
JENKINSFILE_TFVARS_JSON_INDENT               = '          '

def get_terraform_input_vars(terraform_files):
  try:
    raw_json = subprocess.check_output(['terraform-docs', '--no-sort', 'json', '.'])
  except subprocess.CalledProcessError:
    raw_json = '{ "Inputs": [] }'

  return json.loads(raw_json)

def process_terraform_input_vars(visitor, terraform_files):
  json = get_terraform_input_vars(terraform_files)

  result = []
  for input in json['Inputs']:
    result.append(visitor(input))

  return result

def transform_terraform_input_var_to_jenkinsfile_param(input):
  result = 'string(name: "' + input['Name'] + '"'

  if input['Default'] is not None:
    if type(input['Default']) == dict:
      # Was a default value provided?
      if input['Default']['Value'] != '':
        result += ", defaultValue: '"
        # Is it a complex value?
        if type(input['Default']['Value']) in [dict, list]:
          result += json.dumps(input['Default']['Value'])
        else:
          result += input['Default']['Value']
        result += "'"
      else:
        if input['Type'] == 'list':
          result += ", defaultValue: '[]'"
        elif input['Type'] == 'map':
          result += ", defaultValue: '{}'"
    else:
      result += ", defaultValue: '%s'" % input['Default']

  if input['Description'] is not None:
    result += ', description: "%s"' % input['Description']

  result += ')'
  return result

def transform_terraform_input_var_to_tfvars_json(input):
  name = input['Name']

  result = 'tfvars.%s = ' % name

  if input['Type'] in ['list', 'map']:
    result += 'readJSON text: '

  result += 'params.' + name
  return result

def generate_jenkinsfile_params_content(terraform_files, jenkinsfile_path):
  BEGIN_CONTENT_PLACEHOLDER = JENKINSFILE_PARAMS_INDENT + '// BEGINNING OF ' + JENKINSFILE_PARAMS_PRE_COMMIT_HOOK_NAME
  END_CONTENT_PLACEHOLDER = JENKINSFILE_PARAMS_INDENT + '// END OF ' + JENKINSFILE_PARAMS_PRE_COMMIT_HOOK_NAME

  content = ''
  for param in process_terraform_input_vars(transform_terraform_input_var_to_jenkinsfile_param, terraform_files):
    content += JENKINSFILE_PARAMS_INDENT + param + "\n"

  f = open(jenkinsfile_path,'r+')
  result = re.sub(
             r"(" + BEGIN_CONTENT_PLACEHOLDER + ").*?(" + END_CONTENT_PLACEHOLDER + ")",
             r"\1" + "\n" + content + r"\2",
             f.read(),
             flags=re.DOTALL
  )

  f.seek(0)
  f.truncate()
  f.write(result)
  f.close()

def generate_jenkinsfile_tfvars_json_content(terraform_files, jenkinsfile_path, replacements):
  BEGIN_CONTENT_PLACEHOLDER = JENKINSFILE_TFVARS_JSON_INDENT + '// BEGINNING OF ' + JENKINSFILE_TFVARS_JSON_PRE_COMMIT_HOOK_NAME
  END_CONTENT_PLACEHOLDER = JENKINSFILE_TFVARS_JSON_INDENT + '// END OF ' + JENKINSFILE_TFVARS_JSON_PRE_COMMIT_HOOK_NAME

  content = JENKINSFILE_TFVARS_JSON_INDENT + "def tfvars = readJSON text: '{}'\n"
  for param in process_terraform_input_vars(transform_terraform_input_var_to_tfvars_json, terraform_files):
    content += JENKINSFILE_TFVARS_JSON_INDENT + param + "\n"
  content += JENKINSFILE_TFVARS_JSON_INDENT + "writeJSON file: 'terraform.tfvars.json', json: tfvars\n"

  for name in replacements:
    content = content.replace(name, replacements[name])

  f = open(jenkinsfile_path,'r+')
  result = re.sub(
             r"(" + BEGIN_CONTENT_PLACEHOLDER + ").*?(" + END_CONTENT_PLACEHOLDER + ")",
             r"\1" + "\n" + content + r"\2",
             f.read(),
             flags=re.DOTALL
  )

  f.seek(0)
  f.truncate()
  f.write(result)
  f.close()

def main(argv=None):
  parser = argparse.ArgumentParser()
  parser.add_argument('filenames', nargs='*', help='Filenames pre-commit believes have changed.'),
  parser.add_argument('-j', '--jenkinsfile', default='./Jenkinsfile', help="The path to your Jenkinsfile. Defaults to './Jenkinsfile'.")
  parser.add_argument('-r', '--replacements', default='{}', type=json.loads, help="A JSON object that contains arbitrary replacement instructions for the Jenkinsfile. Example: '{ \"params.name\": \"convertToName(params.name.toString())\" }'")

  try:
    args = parser.parse_args(argv)
  except:
    parser.print_help()
    sys.exit(0)

  generate_jenkinsfile_params_content(args.filenames, args.jenkinsfile)
  generate_jenkinsfile_tfvars_json_content(args.filenames, args.jenkinsfile, args.replacements)

if __name__ == '__main__':
  exit(main())
