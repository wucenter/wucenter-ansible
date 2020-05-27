#!/bin/bash -e

########
# CONS #
########

SELF=$( readlink -f "$BASH_SOURCE" )
BASE=$( dirname "$SELF" )

# Force Python2-based ansible installs to use Python3 instead
FORCE_PYTHON3="-e ansible_playbook_python=/usr/bin/python3 -e ansible_python_interpreter=/usr/bin/python3" # DEV: QUOTES UNSUPPORTED

# Vault password file
VAULT_FILE=credentials/VAULT_PASS # DEV: SPACES UNSUPPORTED

# Playbooks
PLAYBOOK_PACK=setup.yml
PLAYBOOK_LINT=lint.yml  # DEV: Static
# PLAYBOOK_LINT=lint_full.yml  # DEV: Dynamic

# requirements.yml
REQUIREMENTS_APPS=roles/requirements.yml
REQUIREMENTS_COLL=ansible_collections/requirements.yml


########
# FUNC #
########

Say()
{
    echo -e "\nINFO  |  $@" >&2
}

Die()
{
    echo -e "\nERROR |  $@" >&2
    exit 1
}

Usage()
{
    cat >&2 <<EOU
USAGE:  $SELF --book ${PLAYBOOK:-PLAYBOOK.yml} [OPTIONS] [MORE_OPTIONS]
DESC:   Ansible playbook wrapper

MODES:
  -P, --book      Mandatory if not shebang-run

OPTIONS:
  -V, --vault     Manage vault password
  -B, --no-bury   Don't write (bury) vCenter cache
  -G, --no-dig    Don't read (dig up) vCenter cache
  -A, --no-auto   Bypass all below:
  -S, --no-synt   Bypass playbook syntax check
  -L, --no-lint   Bypass inventory lint check
  -I, --no-deps   Bypass dependencies update
  -R, --no-role   Bypass additional roles update

MORE_OPTIONS:
  See: ansible-playbook --help
EOU
  # -I, --no-ipam  Bypass IP auto-assignment
    exit $1
}

CheckSetup()
{
    # Check ansible NOT installed by APT
    # IsInstalled() { dpkg-query --show --showformat='${db:Status-Status}\n' ansible 2>/dev/null | grep -q '^installed$' ; }
    # IsInstalled ansible && Die "ansible is installed using APT, remove it manually:\n         sudo apt remove ansible"

    # Check PIP3 installed
    which pip3 &>/dev/null || Die "pip3 is not installed, install it manually:\n         sudo apt install python3-pip"

    # Check ansible is installed
    which ansible &>/dev/null || Die "ansible is not installed, install it manually:\n         sudo pip3 install ansible"

    # Check ansible dependencies
    for dep in ansible-playbook ansible-galaxy ansible-vault ; do
        which $dep &>/dev/null || Die "Missing dependency: $dep"
    done
}

GetAnsibleBasedir() # $1:BOOK_DIR
{
    local base="$( readlink -f "$1" )"
    while [[ ! -f "$base/ansible.cfg" ]] ; do
        base=$( dirname "$base" )
        [[ $base == / ]] && return
    done
       [[ -n $base && -d $base && -r $base && -x $base && -f "$base/ansible.cfg" ]] \
    || Die "Failed to identify playbook parent ansible.cfg location"
    echo "$base"
}


########
# ARGS #
########

# DEV: Linux kernel treats everything following the first “word” in the shebang
#      line as a single argument, see https://lwn.net/Articles/630727/

# WORKAROUND: Exotic args parsing approach
if [[ $1 == --book || $1 == -P ]] ; then
    # Classic run: --book required as arg1 for non-Shebang call
    shift
    PLAYBOOK=$1
    shift
elif [[ -n $1 ]] ; then
    # Shebang run: Parse $1 for options
    for arg in $1; do
        case "$arg" in
            *.yml)         PLAYBOOK=$1 ;;
            -V|--vault)    VAULT=1   ;;
            -A|--no-auto)  NO_SYNT=1 NO_LINT=1 NO_DEPS=1 NO_ROLE=1 NO_IPAM=1 ;;
            -I|--no-deps)  NO_DEPS=1 ;;
            -R|--no-role)  NO_ROLE=1 ;;
            -S|--no-synt)  NO_SYNT=1 ;;
            -L|--no-lint)  NO_LINT=1 ;;
            -I|--no-ipam)  NO_IPAM=1 ;;
            -B|--no-bury)  NO_BURY=1 ;;
            -G|--no-dig)   NO_DIG=1  ;;
            -h|--help)     Usage 0   ;;
            *)             Usage 1   ;;
        esac
    done
    shift
else
    Usage 1
fi



# Parse $@ for options again
while [[ $# -gt 0 ]] ; do case "$1" in
    *.yml)        [[ -z $PLAYBOOK ]] || continue ; PLAYBOOK=$1 ; shift ;;
    -V|--vault)    shift ; VAULT=1   ;;
    -A|--no-auto)  shift ; NO_SYNT=1 NO_LINT=1 NO_DEPS=1 NO_ROLE=1 NO_IPAM=1 ;;
    -I|--no-deps)  shift ; NO_DEPS=1 ;;
    -R|--no-role)  shift ; NO_ROLE=1 ;;
    -S|--no-synt)  shift ; NO_SYNT=1 ;;
    -L|--no-lint)  shift ; NO_LINT=1 ;;
    -I|--no-ipam)  shift ; NO_IPAM=1 ;;
    -B|--no-bury)  shift ; NO_BURY=1 ;;
    -G|--no-dig)   shift ; NO_DIG=1  ;;
    -h|--help)     shift ; Usage 0   ;;
    *) break ;;
esac ; done

# Exports
export NO_BURY NO_DIG


########
# INIT #
########

# Check setup: packages
CheckSetup

# Check playbook
[[ $PLAYBOOK =~ \.yml$ && -f "$PLAYBOOK" && -r "$PLAYBOOK" ]] || Die "Invalid playbook: $1"

# CWD
BASEDIR="$( GetAnsibleBasedir "$( dirname "$PLAYBOOK" )" )"
PLAYDIR="$( readlink -f       "$( dirname "$PLAYBOOK" )" )"
PLAYBOOK="$( readlink -f "$PLAYBOOK" )"
pushd "$BASEDIR" &>/dev/null

# Vault credentials
if [[ -n $VAULT ]] ; then
    if [[ -f $VAULT_FILE ]] ; then
        [[ -s $VAULT_FILE && -r $VAULT_FILE ]] || Die "Invalid vault file: $VAULT_FILE"
        AUTH="--vault-password-file $VAULT_FILE"
    else
        AUTH="--ask-vault-pass"
    fi
    # Implement single password prompt for linting
    if [[ $AUTH == "--ask-vault-pass" && -z $VAULT_PASS && -z $NO_LINT && "$( basename "$PLAYBOOK" )" != "$PLAYBOOK_LINT" ]]; then
        read -s -r -p "[$( basename "$SELF" )] Vault password: " VAULT_PASS
    fi
fi


########
# MAIN #
########

# Install/Update dependencies
if [[ -z $NO_DEPS ]] ; then
    Say Install/update dependencies: collections
    # Ansible collections
    if [[ -f $REQUIREMENTS_COLL ]] ; then
        ANSIBLE_STDOUT_CALLBACK=default \
            ansible-galaxy collection install \
                --requirements-file "$REQUIREMENTS_COLL" \
                --collections-path ./
                # --verbose --force --force-with-deps
    fi
    # Python libraries
    if [[ -f "$PLAYDIR/$PLAYBOOK_PACK" && "$( basename "$PLAYBOOK" )" != "$PLAYBOOK_PACK" ]] ; then
        ansible-playbook $FORCE_PYTHON3 "$PLAYDIR/$PLAYBOOK_PACK" \
            -e "wucenter_basedir=$BASEDIR/"
    fi
fi

# Syntax-check playbook
if [[ -z $NO_SYNT ]] ; then
    Say Syntax checks: $PLAYBOOK
    ansible-playbook $FORCE_PYTHON3 "$PLAYBOOK" --syntax-check
fi

# Install/Update additional roles
if [[ -z $NO_ROLE && -f $REQUIREMENTS_APPS ]] ; then
    Say Install/update dependencies: roles
    ansible-galaxy role install --verbose \
        --role-file  "$REQUIREMENTS_APPS" \
        --roles-path "./roles_galaxy"
        # --verbose --force --force-with-deps
fi

# Lint credentials, inventory, directory, NOT requirements
if [[ -z $NO_LINT && "$( basename "$PLAYBOOK" )" != "$PLAYBOOK_LINT" ]] ; then
    Say Linting inventory
    [[ -f "$PLAYDIR/$PLAYBOOK_LINT" ]] || Die "Missing lint playbook: $PLAYDIR/$PLAYBOOK_LINT"
    if [[ -n $VAULT && $AUTH == "--ask-vault-pass" ]]; then
        [[ -z $VAULT_PASS ]] && Die "Empty Vault password"
        ansible-playbook $FORCE_PYTHON3 "$PLAYDIR/$PLAYBOOK_LINT" "$@" \
            -e "wucenter_basedir=$BASEDIR/" \
            --vault-password-file=/bin/cat <<<"$VAULT_PASS"
    else
        ansible-playbook $FORCE_PYTHON3 "$PLAYDIR/$PLAYBOOK_LINT" "$@" \
            -e "wucenter_basedir=$BASEDIR/" \
            $AUTH
    fi
fi

# TODO Manage IP addr auto assignment
# SCRIPT_IPAM="$BASE/wucenter_ipam.py"
# [[ -z $NO_IPAM ]] && "$SCRIPT_IPAM" inventory/vms.yml

# Play
Say Playbook: $PLAYBOOK
if [[ -n $VAULT && $AUTH == "--ask-vault-pass" && -n $VAULT_PASS ]]; then
    ansible-playbook $FORCE_PYTHON3 "$PLAYBOOK" "$@" \
        -e "wucenter_basedir=$BASEDIR/" \
        --vault-password-file=/bin/cat <<<"$VAULT_PASS"
else
    ansible-playbook $FORCE_PYTHON3 "$PLAYBOOK" "$@" \
        -e "wucenter_basedir=$BASEDIR/" \
        $AUTH
        # WIP -e "vault_args='$AUTH'"
fi
