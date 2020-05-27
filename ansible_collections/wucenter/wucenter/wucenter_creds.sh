#!/bin/bash -e
# DESC: Interactive vaulted credentials creator
# ARGS: -K  Keep Ansible Vault master key



# CONS
VAULT_PASS_FILENAME="VAULT_PASS"



# FUNC
Say()
{
    echo -e "INFO  | $@" >&2
}

Cry()
{
    echo -e "ERROR | $@" >&2
}

AskText() # $1:PROMPT_TEXT
{
    local text
    read -r -p "READ  | Input $1: " text
    echo -n "$text"
}

AskPass() # $1:PROMPT_TEXT
{
    local pass1 pass2
    while true ; do
        read -s -r -p "READ  | Input $1: " pass1
        echo >&2
        read -s -r -p "READ  | Again $1: " pass2
        echo >&2
        [[ $pass1 == $pass2 ]] && break
        Cry "Password mismatch"
    done
    echo -n "$pass1"
}

AskSshk() # $1:PROMPT_TEXT
{
    local sshk
    while true ; do
        echo "READ  | Paste $1, then <ENTER>, then <CTRL+D>" >&2
        sshk=$( </dev/stdin )
           [[ $sshk =~ ^-----BEGIN\ OPENSSH\ PRIVATE\ KEY----- ]] \
        && [[ $sshk =~ -----END\ OPENSSH\ PRIVATE\ KEY-----    ]] \
        && break
           [[ $sshk =~ ^-----BEGIN\ RSA\ PRIVATE\ KEY----- ]] \
        && [[ $sshk =~ -----END\ RSA\ PRIVATE\ KEY-----    ]] \
        && break
        Cry "Invalid OpenSSH private key"
    done
    echo -n "$sshk"
}

VaultKey() # $1:KEY $2:VALUE
{
    # BUG https://github.com/ansible/ansible/issues/28058
    # ansible-vault encrypt_string --name "$1" "$2" --vault-password-file <( echo -n "$vault_pass" )
    # WORKAROUND: FS persist + shred
    ansible-vault encrypt_string --name "$1" "$2" --vault-password-file credentials/"$VAULT_PASS_FILENAME"
}

VaultPipe() # $1:FILE_PATH PIPE:FILE_DATA
{
    cat >"$1"
    local content=$( ansible-vault encrypt "$1" --output - --vault-password-file credentials/"$VAULT_PASS_FILENAME" )
    shred "$1"
    cat <<<"$content" >"$1"
}



# DEPS
for dep in ansible-vault shred ; do
    if ! which $dep &>/dev/null ; then
        Cry "Missing command: $dep"
        exit 1
    fi
done



# INIT
if [[ -e credentials ]] ; then
    Cry "'credentials' directory already exists"
    exit 1
fi



# MAIN: Input
Say "This wizard will create a vaulted credentials bundle at '$(pwd)/credentials/'"

vault_pass=$(    AskPass "Vault master password" )

vcenter_host=$(  AskText "vCenter host" )
vcenter_data=$(  AskText "vCenter datacenter" )
vcenter_user=$(  AskText "vCenter username" )
vcenter_pass=$(  AskPass "vCenter password" )

template_name=$( AskText "Template name" )
template_user=$( AskText "Template username" )
template_pass=$( AskPass "Template password" )

robops_user=$(   AskText "Robops username" )
robops_pass=$(   AskPass "Robops password" )

git_host=$(      AskText "Git host, OPTIONAL" )
if [[ -n $git_host ]] ; then
    git_user=$(  AskText "Git username" )
    git_pass=$(  AskPass "Git password" )
fi

ops_user=$(      AskText "Ops username" )
ops_pass=$(      AskPass "Ops password" )
ops_sshk=$(      AskSshk "Ops SSH private key" )



# MAIN: Output
mkdir credentials

# VAULT_PASS_FILENAME
echo -n "$vault_pass" >credentials/"$VAULT_PASS_FILENAME"

Say "Generating vault.yml: Reentrant vaulting"
cat <<EOY >credentials/vault.yml
---
$( VaultKey "vault_pass" "$vault_pass" )
EOY

Say "Generating vmware.yml: VMware inventory plugin"
# BUG: inventory plugins do not support single variable encryption
# WORKAROUND: complete file encryption
VaultPipe credentials/vmware.yml <<EOY
plugin:         community.vmware.vmware_vm_inventory
hostname:       "$vcenter_host"
username:       "$vcenter_user"
password:       "$vcenter_pass"
validate_certs: false
properties:
- config.name
- config.uuid
- guest.guestId
- guest.net
EOY

Say "Generating vcenter.yml: vCenter API"
cat <<EOY >credentials/vcenter.yml
---
vcenter_host: "$vcenter_host"
vcenter_dc:   "$vcenter_data"
vcenter_user: "$vcenter_user"
$( VaultKey "vcenter_pass" "$vcenter_pass" )
EOY

Say "Generating template.yml: vCenter template"
cat <<EOY >credentials/template.yml
---
template_name: "$template_name"
template_user: "$template_user"
$( VaultKey "template_pass" "$template_pass" )
EOY

Say "Generating robops.yml: vCenter Guest Tools user"
cat <<EOY >credentials/robops.yml
---
robops_user: "$robops_user"
$( VaultKey "robops_pass" "$robops_pass" )
EOY

if [[ -n $git_host ]] ; then
    Say "Generating git.yml: Git creds"
    cat <<EOY >credentials/git.yml
---
git_host: "$git_host"
git_user: "$git_user"
$( VaultKey "git_pass" "$git_pass" )
EOY
fi

Say "Generating ops.yml: Apps roles SSH user"
cat <<EOY >credentials/ops.yml
---
ops_user: "$ops_user"
$( VaultKey "ops_pass" "$ops_pass" )
$( VaultKey "ops_sshk" "$ops_sshk" )
EOY



# MAIN: Post
chmod 660 credentials/*
[[ $1 != '-K' ]] && shred -u credentials/"$VAULT_PASS_FILENAME"
# DBG tail -n 1000  credentials/* >&2
Say "Done"
