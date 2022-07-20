#!/usr/bin/env bash
shopt -s nullglob
set -e

# private-files-restore.sh
#
# This script is used to restore private and sensitive files, such as ssh keys and
# gpg keys, from an encrypted AWS S3 bucket.
#
# Note: this script assumes you are logged in with access to the AWS S3 bucket
# below and that the AWS CLI is installed.

# Set the bucket name and profile. This can be overwritten if needed.
profile=${DOTFILES_PRIVATE_PROFILE:-dwmkerr}
bucket=${DOTFILES_PRIVATE_S3_BUCKET:-dwmkerr-dotfiles-private}

# Helper function to restore files after checking with the user first.
function restore_safe() {
    echo -n "Restore '$1' to '$2'? [y/n]: "
    read yesno
    if [[ $yesno =~ ^[Yy] ]]; then
        mkdir -p "$(dirname $2)"
        echo "Preparing to run: aws s3 cp \"$1\" \"$2\" $3 --profile \"${profile}"
        aws s3 cp "$1" "$2" $3 --profile "${profile}"
    fi
}

# Helper function to check if an AWS profile exists.
function aws_profile_exists() {

    local profile_name="${1}"
    echo -n "Checking for AWS profile: '${profile_name}'... "
    local profile_name_check=$(cat $HOME/.aws/config | grep "\[profile ${profile_name}]")

    if [ -z "${profile_name_check}" ]; then
        echo "profile doesn't exist"
        return 1
    else
        echo "profile exists"
        return 0
    fi
}

# Alicloud CLI configuration and credentials.
restore_safe "s3://${bucket}/aliyun/config.json" "$HOME/.aliyun/" 

# AWS CLI configuration and credentials
restore_safe "s3://${bucket}/aws/config" "$HOME/.aws/"
restore_safe "s3://${bucket}/aws/credentials" "$HOME/.aws/"

# Azure CLI configuration and credentials.
restore_safe "s3://${bucket}/azure/config" "$HOME/.azure/"

# Google Cloud CLI configuration and credentials.
echo -n "Restore Google Cloud configuration and credentials? (Warning, will overwrite existing) [y/n]: "
read yesno
if [[ $yesno =~ ^[Yy] ]]; then
    dest="$HOME/.config/gcloud/"
    mkdir -p "${dest}"
    aws s3 sync "s3://${bucket}/config/gcloud" "${dest}"
fi

# Restore SSH keys and config.
echo -n "Restore SSH keys and configuration? (Warning, will overwrite existing) [y/n]: "
read yesno
if [[ $yesno =~ ^[Yy] ]]; then
    dest="$HOME/.ssh/"
    mkdir -p "${dest}"
    aws s3 sync "s3://${bucket}/ssh" "${dest}"

    # Folders are owned by curent user, private keys are 600, public keys are 644.
    chmod 700 ~/.ssh
    find ~/.ssh -type f -exec chmod 0600 {} \;
    find ~/.ssh -type f -exec chmod 0644 {} \;
    find ~/.ssh -type d -exec chmod 0700 {} \;

fi

# Restore GPG secret keys.
echo -n "Restore backup GPG keys? (Warning, will overwrite existing) [y/n]: "
read yesno
if [[ $yesno =~ ^[Yy] ]]; then
    aws s3 cp "s3://${bucket}/gpg/secret-keys.asc" - | gpg --import
fi

# Restore GPG trust database.
echo -n "Restore GPG trust database? (Warning, will overwrite existing) [y/n]: "
read yesno
if [[ $yesno =~ ^[Yy] ]]; then
    aws s3 cp "s3://${bucket}/gpg/trust-database.txt" - | gpg --import-ownertrust
fi
