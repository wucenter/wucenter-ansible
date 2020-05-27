#!/bin/bash -e
# DESC
# ARGS  $1  BASEDIR
# ARGS  $2  PLAY_DST


# FUNC

Say()
{
    echo -e "INFO  |  $@" >&2
}

Die()
{
    echo -e "ERROR |  $@" >&2
    exit 1
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

InstallBooks() # $1:BOOKS_SRC $2:BOOKS_DST $1:PLAYER_PATH
{
    local book_src_dir=$1
    local book_dst_dir=$2
    local play_path=$3

    [[ -e $book_dst_dir ]] || mkdir -p "$book_dst_dir"
    [[ -d $book_dst_dir ]] || Die "Failed to create $book_dst_dir"

    Say Install WUcenter playbooks to: $book_dst_dir
    cp "$book_src_dir"/*.yml "$book_dst_dir"
    sed -i -E \
        '0,/^(#!)\.\/(wucenter_player\.sh)(\s.*)?$/ s##\1'"$play_path"'\3#' \
        "$book_dst_dir/"*.yml
}

InstallPlayer() # $1:PLAYER_SRC $2:PLAYER_DST
{
    local player_src=$1
    local player_dst=$2
    local player_dst_dir="$( dirname "$player_dst" )"

    [[ -e $player_dst_dir ]] || mkdir -p "$player_dst_dir"
    [[ -d $player_dst_dir ]] || Die "Failed to create $player_dst_dir"

    local player_src=$1
    local player_dst=$2

    Say Install WUcenter player to:    $player_dst
    cp "$player_src" "$player_dst"
}

InstallWorkspace() # $1:CONFIG_SRC $2:CONFIG_DST
{
    local config_src=$1
    local config_dst=$2

    Say Install Ansible config to:     $config_dst
    cp "$config_src" "$config_dst"
    # credentials
    # inventory
    # roles
    # roles_galaxy
}

InstallDeps() # $1:SETUP_PLAYBOOK_PATH
{
    local play_setup=$1

    Say Install WUcenter dependencies:  $play_setup
    "$play_setup"
}


# CONST
SELF=$( readlink -f "$BASH_SOURCE" )
BASE=$( dirname "$SELF" )
CONF_SRC="$BASE"/ansible.cfg
BOOK_SRC="$BASE"/playbooks
PLAY_SRC="$BASE"/wucenter_player.sh
BOOK_SETUP=setup.yml


# INIT
[[ -f $PLAY_SRC ]] || Die "Failed to locate player: $PLAY_SRC"
[[ -d $BOOK_SRC ]] || Die "Failed to locate playbooks dir: $BOOK_SRC"


# ARGS
CONF_DST="$( realpath --canonicalize-missing "$BASE/../../../ansible.cfg" )"
BOOK_DST="$( realpath --canonicalize-missing "${1:-$BASE/../../../books}" )"
PLAY_DST="$( realpath --canonicalize-missing "${2:-$BOOK_DST}" )/$( basename "$PLAY_SRC" )"


# MAIN
if [[ -z "$( GetAnsibleBasedir "$BOOK_DST" )" ]] ; then
    InstallWorkspace "$CONF_SRC" "$CONF_DST"
    # Die "Playbooks directory MUST be under an Ansible basedir (contains ansible.cfg)"
fi
InstallPlayer "$PLAY_SRC" "$PLAY_DST"
InstallBooks  "$BOOK_SRC" "$BOOK_DST" "$PLAY_DST"
InstallDeps   "$BOOK_DST/$BOOK_SETUP"
