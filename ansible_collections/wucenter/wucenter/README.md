# WUcenter

<div align="center"><p align="center"><img src="https://raw.githubusercontent.com/wucenter/wucenter-branding/master/wucenter_logo_rect.png" title="WUcenter logo"></p></div>
<div align="center"><p align="center">Ansible framework for managing Ubuntu virtual machines on VMware vCenter</p></div>

<!-- MarkdownTOC autolink="true" style="unordered" -->

- [Features](#features)
  - ["Elastic" resources](#elastic-resources)
  - [Configurable resources](#configurable-resources)
  - [Additional roles management](#additional-roles-management)
  - [Transparent Ansible Vault support](#transparent-ansible-vault-support)
- [Requirements](#requirements)
- [Quick Install](#quick-install)
- [Getting started](#getting-started)
- [Documentation](#documentation)
  - [Setup](#setup)
  - [Workspace](#workspace)
  - [Player](#player)
    - [Features](#features-1)
    - [Usage](#usage)
  - [Playbooks](#playbooks)
  - [Credentials](#credentials)
    - [Credentials Spec](#credentials-spec)
    - [Using Ansible Vault](#using-ansible-vault)
  - [VMs Inventory](#vms-inventory)
    - [VMs Inventory Spec](#vms-inventory-spec)
      - [VMs automation tags](#vms-automation-tags)
      - [VMs roles tags](#vms-roles-tags)
  - [Users directory](#users-directory)
    - [Users directory Spec](#users-directory-spec)
  - [References](#references)
- [Roadmap](#roadmap)

<!-- /MarkdownTOC -->

## Features

- Comprehensive lifecycle management (provision, rename, re-align, decommission)
- Hot-scalable virtual hardware resources
- Out-of-band provisioning & alignment, vCenter API in place of SSH
- Burying: cache scanned state in vCenter custom attributes
- Template-based provisionning includes admins, SSH keys
- Feature-rich YAML inventory format, with linting
- Fine-grained automation features control, with `auto/*` tags
- Tag-based roles management, with `apps/*` and `galaxy/*` tags
- State auditing, inventory canonicalization

### "Elastic" resources

Scale virtual hardware resources without rebooting:

- CPU (number of cores)
- RAM (MB)
- Root FS (MB)
- Swap (MB)

### Configurable resources

- HW flags: power state, hotplug ram/cpu, reserved ram
- vCenter references: datacenter, cluster, folder, datastore, network
- Network config using [Netplan](https://netplan.io)
- Admin users, including SSH keys

### Additional roles management

- Tags-based roles assignation
- Ansible Galaxy supported, with auto-updates

### Transparent Ansible Vault support

- Included WUcenter credentials wizard helps creating a vaulted credentials bundle
- Included WUcenter player reads the master vault password interactively, or either as a file or an env var

## Requirements

- VMware vCenter cluster
    + version >=6.7U3
- Ansible control host
    + Python 3
    + Ansible version >=2.9.6
    + tested on Ubuntu bionic
- Ubuntu bionic (18.04) VM template (not published yet)
    + static IP
    + password-less sudoer user
    + configured APT
    + pre-installed Python 3 & VMware Guest Tools
- Limitation: Ansible check-mode is not supported

## Quick Install

These install instructions are here for *experimented* users, detailed instructions follow.

First install Ansible for Python3:

```
sudo apt install python3-pip
sudo -H pip3 install --no-cache-dir --upgrade pip ansible
```

Then create WUcenter workspace:

``` bash
mkdir workspace
cd workspace
ansible-galaxy collection install wucenter.wucenter -p ./
ansible_collections/wucenter/wucenter/wucenter_setup.yml
ansible_collections/wucenter/wucenter/wucenter_creds.yml
mkdir inventory roles
touch inventory/users.yml inventory/vms.yml
```


## Getting started

0. Install requirements

WUcenter is tested on Ubuntu bionic with Ansible for Python 3.

Once you installed the `python3-pip` package you can install Ansible with `pip3`:

```
sudo -H pip3 install --no-cache-dir ansible
```

1. Install WUcenter software

- either, pull last tagged version from Ansible Galaxy into existing Ansible workspace

``` bash
cd $EXISTING_WORKSPACE
ansible-galaxy collection install wucenter.wucenter -f -p ./
```

- or, clone current master from Github as a new Ansible workspace

``` bash
cd $SOMEWHERE
git clone https://github.com/wucenter/wucenter $NEW_WORKSPACE_NAME
```

- finally, run WUcenter installation script

``` bash
ansible_collections/wucenter/wucenter/wucenter_setup.sh
```

2. Configure WUcenter credentials

- either, use WUcenter Vaulted credentials wizard

``` bash
ansible_collections/wucenter/wucenter/wucenter_creds.sh
```

- or manually edit plain-text files, see `samples/credentials/*.yml` and read Credentials Spec below

3. Configure WUcenter inventory

WUcenter requires 2 files, check `samples/inventory/`.
- `inventory/vms.yml` for defining virtual machines, theirs specs & their roles
- `inventory/users.yml` admin users directory

4. Optional: roles

- copy your custom Ansible roles to `roles/`

- configure `roles/requirements.yml` to automatically install pristine roles to `roles_galaxy/`

## Documentation

### Setup

Once `wucenter.wucenter` collection has been deployed to `./ansible_collections` directory, run `wucenter_setup.sh` to setup your Ansible workspace with WUcenter:

- Install WUcenter player
- Generate WUcenter playbooks
- Install/update Python librairies (pip3)
- Install/update Ansible collections/roles
- Setup Ansible configuration (`ansible.cfg`)

### Workspace

Workspace layout:

- `ansible-collections/` Ansible collections managed by `ansible-collections/requirements.yml`
- `ansible-collections/wucenter/wucenter/` WUcenter software
- `ansible.cfg` WUcenter Ansible defaults, generated by `wucenter_setup.sh`
- `books/` WUcenter playbooks, generated by `wucenter_setup.sh`
- `credentials/` WUcenter credentials bundle, generated by `wucenter_creds.sh`
- `inventory/users.yml` WUcenter operators directory
- `inventory/vms.yml` WUcenter virtual machines inventory
- `roles/` Custom Ansible roles
- `roles_galaxy/` Pristine Ansible roles, managed by `roles/requirements.yml`

Recommended usage is to have `credentials/`, `inventory/` and `roles/` symlinked to GIT repos.

### Player

All playbooks are meant to be used with the provided playbook player `wucenter_player.sh`.

All playbooks include a shebang to call the player transparently.

#### Features

- Ansible setup checking
- Playbook roles syntax checking
- Hosts inventory linting
- Users directory linting
- Remote roles updating
- Single-command run, no need to `cd`
- Vault password management
    - using variable, if `VAULT_PASS` env set
    - using file, if `credentials/VAULT_PASS` file exists
    - *single* interactive password prompt otherwise

#### Usage

The player accepts the following options:

```
USAGE:  wucenter_player.sh --book PLAYBOOK.yml [OPTIONS] [MORE_OPTIONS]
DESC:   Ansible playbook wrapper

MODES:
  -P, --book PB   Mandatory if not shebang-run

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
```

It is possible to specify `ansible-playbook` options **after** the player's ones:

``` bash
./scan.yml -A -F -vv --limit localhost,myhost
```

The above command will scan `myhost` VM:

- Bypass all additional player features (`-A`)
- Force full scan, disabling bury cache (`-F`)
- Pass additional options to `ansible-playbook` (`-vv --limit localhost,myhost`)
- Please note that inventory limiting (using `--limit` or `-l`) **requires** `localhost` inclusion

### Playbooks

`apply.yml` is the main entrypoint, featuring a minimalistic Gitops workflow. It combines the following playbooks:

- `scan.yml` Gather VMs state
- `decommission.yml` Remove VMs
- `provision.yml` Create VMs from template
- `rename.yml` Change VMs name
- `align.yml` Align VMs specs
- `apps.yml` Play tagged roles

More playbooks are provided:

- `lint.yml` Lint desired state (inventory)
- `lint_full.yml` Lint desired state (vCenter)
- `audit.yml` Show VMs specs divergences (desired/scanned/cached)
- `updates.yml` Show available APT updates
- `setup.yml` Install WUcenter workspace dependencies
- `init.yml` WUcenter internals

### Credentials

Following credentials definitions are required:
+ vCenter server admin
+ Template password-less sudoer (for provisioning)
+ `robops` sudoer (for alignment)
+ `ops` SSH sudoer (for additional roles)
+ Private GIT user (for custom roles, optional)

Configuration consists of YAML files in `credentials` directory (or symlink).

| Main playbooks     | `vcenter.yml` | `template.yml` | `robops.yml` | `ops.yml` | `git.yml` | `vmware.yml` |
| :-------------     | :---          | :---           | :---         | :---      | :---      | :---         |
| `apply.yml`        | ✔             | ✔              | ✔            | ✔         | ❓         |              |
| `scan.yml`         | ✔             |                |              |           |           |              |
| `decommission.yml` | ✔             |                |              |           |           |              |
| `rename.yml`       | ✔             |                | ✔            |           |           |              |
| `provision.yml`    | ✔             | ✔              |              |           |           |              |
| `align.yml`        | ✔             |                | ✔            |           |           |              |
| `apps.yml`         | ✔             |                |              | ✔         | ❓         |              |
| More playbooks     |               |                |              |           |           |              |
| `lint_full.yml`    | ✔             | ✔              | ✔            | ✔         |           | ✔            |
| `lint.yml`         | ✔             | ✔              | ✔            | ✔         |           |              |
| `audit.yml`        | ✔             |                | ✔            |           |           |              |
| `updates.yml`      |               |                | ✔            |           |           |              |
| `init.yml`         | ✔             | ✔              | ✔            | ✔         |           |              |
| `setup.yml`        |               |                |              |           |           |              |

Credential files supports Ansible Vault both for full file-vaulting and for YAML key vaulting.

Use the provided interactive wizard to generate a complete credentials bundle or follow the credentials spec to populate your `credentials` directory.

To interactively populate all required credentials, run from project base directory:
``` bash
ansible_collections/wucenter/wucenter/wucenter_creds.sh
```

#### Credentials Spec

- In `credentials/vcenter.yml`:

| vC Credentials | Description                  |
| :------------- | :-----                       |
| `vcenter_host` | STRING vCenter Host          |
| `vcenter_dc`   | STRING vCenter Datacenter Id |
| `vcenter_user` | STRING vCenter Username      |
| `vcenter_pass` | STRING vCenter Password      |

- Full linting uses [vmware_vm_inventory](https://docs.ansible.com/ansible/latest/plugins/inventory/vmware_vm_inventory.html) dynamic inventory plugin.
This requires an additional configuration file that does not support selective vaulting: `credentials/vmware.yml`:

| Plugin Credentials | Description                                                  |
| :-------------     | :-----                                                       |
| `plugin`           | CONST `community.vmware.vmware_vm_inventory`                 |
| `hostname`         | STRING vCenter Host                                          |
| `username`         | STRING vCenter Username                                      |
| `password`         | STRING vCenter Password                                      |
| `validate_certs`   | BOOL vCenter self-signed certificate                         |
| `properties`       | CONST `[config.name, config.uuid, guest.guestId, guest.net]` |

- Template password-less sudoer

Used for provisioning: `credentials/template.yml`

| TPL Credentials | Description                           |
| :-------------- | :------------------------------------ |
| `template_name` | STRING Template vCenter Id            |
| `template_user` | STRING Username, password-less sudoer |
| `template_pass` | STRING Password                       |

- `robops` sudoer

Used for alignment: `credentials/robops.yml`

| VM Credentials | Description     |
| :------------  | :-------------- |
| `robops_user`  | STRING Username |
| `robops_pass`  | STRING Password |

- `ops` SSH sudoer

Used for additional roles: `credentials/ops.yml`

| VM Credentials | Description            |
| :------------  | :--------------        |
| `ops_user`     | STRING Username        |
| `ops_pass`     | STRING Password        |
| `ops_sshk`     | STRING SSH private key |

- *Optional* Private GIT cloner

For specific roles: `credentials/git.yml`

| TPL Credentials | Description                           |
| :-------------- | :------------------------------------ |
| `git_host`      | STRING Template vCenter Id            |
| `git_user`      | STRING Username                       |
| `git_pass`      | STRING Password                       |

#### Using Ansible Vault

- Encrypt vault single variable
``` bash
ansible-vault encrypt_string --name 'git_pass' 's3(r3t' --vault-password-file credentials/VAULT_PASS
```

- Decrypt vault single variable
``` bash
ansible localhost -m debug -a var='git_pass' -e "@credentials/git.yml" --vault-password-file credentials/VAULT_PASS
```

### VMs Inventory

Virtual machines inventory is defined by an [inventory YAML file](https://docs.ansible.com/ansible/latest/plugins/inventory/yaml.html) in `inventory/vms.yml`.

This enables multi-level variables overrides. Recommended usage is mapping projects to vCenter folders.

#### VMs Inventory Spec

Each VM identified by a **unique** key, holds the following attributes:

| VM Unique Id | Description                                                |
| :----------  | :--------------------------------------------------------- |
| `vm_name`    | OPTIONAL STRING Hostname. Defaults to `VM_KEY.vm_net_sd`   |
| `vm_folder`  | OPTIONAL STRING Must start with `/`. Defaults to `/`       |

| vC Resources   | Description                |
| :------------- | :------------------------- |
| `vm_cluster`   | STRING vCenter cluster     |
| `vm_datastore` | STRING vCenter datastore   |
| `vm_network`   | STRING vCenter network     |

| VM Hardware        | Description                        |
| :-----------       | :--------------------------------- |
| `vm_power`         | BOOL Power state                   |
| `vm_hotplug`       | BOOL Hot-scalable CPU/RAM          |
| `vm_ram_reserved`  | BOOL Reserve RAM                   |
| `vm_ram`           | INT Memory (MB)                    |
| `vm_cpu`           | INT Number of cores                |
| `vm_disk`          | INT Root filesystem (MB)           |
| `vm_swap`          | INT Swap (MB)                      |

| VM Network   | Description              |
| :----------- | :----------------------- |
| `vm_net_ip`  | IP VM                    |
| `vm_net_gw`  | IP Gateway               |
| `vm_net_nm`  | IP VM Netmask            |
| `vm_net_ns1` | IP DNS Server 1          |
| `vm_net_ns2` | IP DNS Server 2          |
| `vm_net_sd`  | STRING DNS Search Domain |

| VM Mgmt   | Description                      |
| :-------- | :----------                      |
| `vm_auto` | LIST[STRING] See automation tags |

| VM Roles   | Description                          |
| :--------  | :----------                          |
| `vm_roles` | OPTIONAL LIST[STRING] See roles tags |
| `vm_vars`  | OPTIONAL DICT[STRING] See roles tags |

| VM Renaming | Description              |
| :---------  | :----------------------- |
| `vm_rename` | OPTIONAL STRING New name |

| VM Removal | Description                                         |
| :--------- | :-------------------------------------------------- |
| `state`    | OPTIONAL STRING Set to `absent` for decommissioning |

##### VMs automation tags

`vm_auto` toggles automation features:

- `auto` = `auto/all`
    + `auto/manage`
        * `auto/provision`
        * `auto/decommission`
        * `auto/rename`
        * `auto/roles`
        * `auto/folder`
        * `auto/bury`
    + `auto/hw`
        * `auto/power`
        * `auto/cpu`
        * `auto/ram`
        * `auto/hwflags`
            - `auto/hotplug`
            - `auto/ram_reserved`
    + `auto/data`
        * `auto/datastore`
        * `auto/disks`
            - `auto/disk`
            - `auto/swap`
    + `auto/net`
        * `auto/network`
        * `auto/netconf`
        * `auto/hostname`
        * `auto/ssh` requires `auto/user`
    + `auto/user`
    <!-- + TODO `auto/ipam` ? -->

##### VMs roles tags

`vm_roles` can specify:

- `apps/*` tags to reference in-house or patched roles from `roles` directory
- `galaxy/*` tags to reference pristine 3rd-party roles from `roles_galaxy` directory, those should be declared in `roles/requirements.yml` to benefit from automatic installation/update.

Optionally, `vm_vars` can specify custom variables used by roles. Contained variables will get copied to the root level at runtime.

Alternatively it is possible to define those directly at the root level (hostvars), in this case, defined variables won't get burried to vCenter custom attributes, thus protecting sensitive information.

### Users directory

Users directory is defined by a custom YAML file.

Users directory is necessary to provision & align admin credentials sush as hashed user password or ssh public key.

Users directory can be easily extended for custom roles.

User management is currently limited to two hard-coded groups:

1. `robops`, robots, password-less sudoers, NOT AUTHORIZED to connect over SSH
1. `ops`, human Ops, sudoers, MUST setup SSH key(s) to access VM


| Main playbooks     | `robops` | `ops` |
| :-------------     | :---     | :---  |
| `apply.yml`        | ✔        | ✔     |
| `scan.yml`         | ✔        |       |
| `decommission.yml` |          |       |
| `rename.yml`       | ✔        |       |
| `provision.yml`    | ✔        |       |
| `align.yml`        | ✔        |       |
| `apps.yml`         |          | ✔     |
| More playbooks     |          |       |
| `lint_full.yml`    | ✔        |       |
| `lint.yml`         | ✔        |       |
| `audit.yml`        | ✔        |       |
| `updates.yml`      | ✔        |       |
| `init.yml`         |          |       |
| `setup.yml`        |          |       |

#### Users directory Spec

- Declare `users` dictionary in `inventory/users.yml`:

| User spec    | Description                                                 |
| :----------- | :-------------------------                                  |
| `user_name`  | STRING This is the GECOS, the username is the dict key !    |
| `user_hash`  | STRING Hashed password, `mkpasswd --method=SHA-512 --stdin` |
| `user_tags`  | LIST[STRING]                                                |
| `user_keys`  | LIST[DICT] SSH Keys Specs                                   |
| `user_state` | STRING OPTIONAL Set to `absent` to remove user              |

- `user_keys` dictionaries attributes:

| Key spec     | Description                                   |
| :----------- | :-------------------------                    |
| `ssh_rsa`    | STRING SSH Public key                         |
| `comment`    | STRING OPTIONAL                               |
| `state`      | STRING OPTIONAL Set to `absent` to remove key |

- Supported `user_tags`:

| User tags    | Description                      |
| :----------- | :-------------------------       |
| `robops`     | User for alignment (vCenter API) |
| `ops`        | User for additional roles (SSH)  |

### References

- [Ansible VMware modules](https://docs.ansible.com/ansible/latest/modules/list_of_cloud_modules.html#vmware)
- [Ansible VMware source code (=2.9.9)](https://github.com/ansible/ansible/tree/v2.9.9/lib/ansible/modules/cloud/vmware)
- [Ansible VMware source code (>=2.10)](https://github.com/ansible-collections/vmware/tree/master/plugins/modules)
- [Ansible core filters](https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/filter/core.py)
- [Jinja2 builtin filters](https://jinja.palletsprojects.com/en/2.11.x/templates/#list-of-builtin-filters)
- [JMESPath spec](https://jmespath.org/specification.html) (`json_query()`)
- [Python regular expressions](https://docs.python.org/3/library/re.html)
- [YAML Block Chomping](https://yaml-multiline.info/)
- [YAML Gotchas](https://www.arp242.net/yaml-config.html)

## Roadmap

- IP Assignation management
- Implement [DRS affinities](https://docs.ansible.com/ansible/latest/modules/vmware_vm_vm_drs_rule_module.html)
- Minimal VM healthchecks
    - df root_fs
    - resolv dns1
    - ping gw
    - apt update
