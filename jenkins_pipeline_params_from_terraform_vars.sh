#!/usr/bin/env bash

set -e

readonly JENKINSFILE="Jenkinsfile"

readonly JENKINSFILE_PARAMS_ID='JENKINS-PIPELINE-PARAMS-FROM-TERRAFORM-INPUT-VARS'
readonly JENKINSFILE_PARAMS_PRE_COMMIT_HOOK_NAME="$JENKINSFILE_PARAMS_ID PRE-COMMIT HOOK"
readonly JENKINSFILE_PARAMS_INDENT='    '

readonly JENKINSFILE_TFVARS_JSON_ID='JENKINS-PIPELINE-PARAMS-TO-TERRAFORM-TFVARS-JSON'
readonly JENKINSFILE_TFVARS_JSON_PRE_COMMIT_HOOK_NAME="$JENKINSFILE_TFVARS_JSON_ID PRE-COMMIT HOOK"
readonly JENKINSFILE_TFVARS_JSON_INDENT='          '

get_default_from_text() {
    local TEXT="$1"

    echo "$TEXT" | grep -e 'Default: .*\.' | sed -E 's/^.*Default: (.*)\..*$/\1/'
}

inline_content() {
    local CONTENT="$1"

    local TMP_FILE=$(mktemp)
    local TMP_PLACEHOLDER='I_SHALL_BE_REPLACED'

    printf "$CONTENT\n" > "$TMP_FILE"

    # Replace content between MARKER_BEGINNING and MARKER_END with TMP_PLACEHOLDER (see https://stackoverflow.com/questions/1212799/how-do-i-extract-lines-between-two-line-delimiters-in-perl#1212834).
    MARKER_BEGINNING="$2" \
    MARKER_END="$3" \
    TMP_PLACEHOLDER="$TMP_PLACEHOLDER" \
    perl -i -ne 'if (/$ENV{MARKER_BEGINNING}/../$ENV{MARKER_END}/) { print $_ if /$ENV{MARKER_BEGINNING}/; print "$ENV{TMP_PLACEHOLDER}\n$_" if /$ENV{MARKER_END}/;} else { print $_ }' "$JENKINSFILE"

    # Replace TMP_PLACEHOLDER with the desired content.
    TMP_PLACEHOLDER="$TMP_PLACEHOLDER" \
    perl -i -e 'open(F, "'"$TMP_FILE"'"); $f = join "", <F>; while(<>){if (/$ENV{TMP_PLACEHOLDER}/) {print $f} else {print $_};}' "$JENKINSFILE"

    rm -f "$TMP_FILE"
}

is_quoted_string() {
    echo "$1" | grep -qe '^".*"$'
    return $?
}

process_terraform_variables() {
    local PRODUCER="$1"

    local VARIABLES=$(terraform-docs json . | jq '[ .Inputs[] | { type: .Type, name: .Name, description: .Description, default: .Default.Literal }]' )

    local result=""

    IFS=$'\n'
    for var in $(echo "$VARIABLES" | jq -c '.[]'); do
        var_type="$(echo "$var" | jq -r .type)"
        var_name="$(echo "$var" | jq -r .name)"
        var_description="$(echo "$var" | jq .description)"
        var_default="$(echo "$var" | jq .default)"

        result+=$($PRODUCER "$var_type" "$var_name" "$var_description" "$var_default")
        result+=$'\n'
    done

    echo "$result"
}

produce_jenkinsfile_params() {
    local VAR_TYPE="$1"
    local VAR_NAME="$2"
    local VAR_DESCRIPTION="$3"
    local VAR_DEFAULT="$4"

    local result=""
    result+="${JENKINSFILE_PARAMS_INDENT}string"
    result+="(name: \"$VAR_NAME\""

    # Create 'defaultValue' attribute iff variable is not required.
    if [ "$VAR_DEFAULT" != "null" ]; then
        # Check if variable description defines a default value.
        local DEFAULT=$(get_default_from_text $VAR_DESCRIPTION)
        if [ "$DEFAULT" != "" ]; then
            # Create 'defaultValue' attribute from description.
            if ! is_quoted_string "$DEFAULT"; then
                DEFAULT="\"$DEFAULT\""
            fi

            result+=", defaultValue: $DEFAULT"
        # Otherwise derive default value from the variable itself.
        else
            # Override default if variable is of complex type (for which terraform-doc reports "").
            if [ "$VAR_TYPE" == "list" ] && [ "$VAR_DEFAULT" == '""' ] ; then
                result+=', defaultValue: "[]"'
            elif [ "$VAR_TYPE" == "map" ] && [ "$VAR_DEFAULT" == '""' ] ; then
                result+=', defaultValue: "{}"'
            # Otherwise use provided default value.
            else
                result+=", defaultValue: $VAR_DEFAULT"
            fi
        fi
    fi

    if [ "$VAR_DESCRIPTION" != '""' ]; then
        result+=", description: $VAR_DESCRIPTION"
    fi

    result+=')'

    echo "$result"
}

produce_jenkinsfile_tfvars_json() {
    local VAR_TYPE="$1"
    local VAR_NAME="$2"
    local VAR_DESCRIPTION="$3"
    local VAR_DEFAULT="$4"

    echo "${JENKINSFILE_TFVARS_JSON_INDENT}tfvars.$VAR_NAME = params.$VAR_NAME.toString()"
}

JENKINSFILE_PARAMS_CONTENT=$(process_terraform_variables produce_jenkinsfile_params)
inline_content "$JENKINSFILE_PARAMS_CONTENT" "BEGINNING OF $JENKINSFILE_PARAMS_PRE_COMMIT_HOOK_NAME" "END OF $JENKINSFILE_PARAMS_PRE_COMMIT_HOOK_NAME"

JENKINSFILE_TFVARS_JSON_CONTENT="${JENKINSFILE_TFVARS_JSON_INDENT}def tfvars = readJSON text: '{}'\n"
JENKINSFILE_TFVARS_JSON_CONTENT+="$(process_terraform_variables produce_jenkinsfile_tfvars_json)\n"
JENKINSFILE_TFVARS_JSON_CONTENT+="${JENKINSFILE_TFVARS_JSON_INDENT}writeJSON file: 'terraform.tfvars.json', json: tfvars"
inline_content "$JENKINSFILE_TFVARS_JSON_CONTENT" "BEGINNING OF $JENKINSFILE_TFVARS_JSON_PRE_COMMIT_HOOK_NAME" "END OF $JENKINSFILE_TFVARS_JSON_PRE_COMMIT_HOOK_NAME"
