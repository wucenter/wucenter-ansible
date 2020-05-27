# vmware_vm_textfile

This role writes specified content in specified file on remote VM (using `vmware_vm_shell` module).

Module `vmware_vm_shell` uses VMware Guest Tools to interact with the VM out-of-band (vCenter API instead of Ansible SSH).

## Requirements

This module executes sudo-ed commands using `vmware_vm_shell` module, thus it MUST get run by a **password-less** sudoer.

## Variables

| Variable                  | Required   | Description                                         |
| :======================== | ========== | =================================================== |
| vcenter_host              | true       |                                                     |
| vcenter_dc                | true       |                                                     |
| vm_username               | true       |                                                     |
| vm_password               | true       |                                                     |
| vm_name                   | true       |                                                     |
| vm_folder                 | true       |                                                     |
| vmware_vm_textfile_path   | true       | STRING  File path                                   |
| vmware_vm_textfile_data   | true       | STRING  File contents                               |

## Samples

~~~ yaml
- name: "vSphere | Test File"
  vars:
    vmware_vm_textfile_path: "/tmp/this is a test file name"
    vmware_vm_textfile_data: |
      This is text file
      Multiline content
  import_role:
    name:                    vmware_vm_textfile
~~~

## Roadmap

- mod_perms
- own_user
- own_group
