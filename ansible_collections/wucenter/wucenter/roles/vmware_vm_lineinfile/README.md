# vmware_vm_lineinfile

This role sets specified line in specified file on remote VM (using `vmware_vm_shell` module).

Module `vmware_vm_shell` uses VMware Guest Tools to interact with the VM out-of-band (vCenter API instead of Ansible SSH).

## Requirements

This module executes sudo-ed commands using `vmware_vm_shell` module, thus it MUST get run by a **password-less** sudoer.

## Variables

| Variable                    | Required   | Description                                         |
| :========================== | ========== | =================================================== |
| vcenter_host                | true       |                                                     |
| vcenter_dc                  | true       |                                                     |
| vm_username                 | true       |                                                     |
| vm_password                 | true       |                                                     |
| vm_name                     | true       |                                                     |
| vm_folder                   | false      |                                                     |
| vmware_vm_lineinfile_path   | true       | STRING  File path                                   |
| vmware_vm_lineinfile_line   | true       | STRING  Line data                                   |

## Samples

~~~ yaml
- name: "vSphere | Test Line"
  vars:
    vmware_vm_lineinfile_path: "/tmp/this is a test file name"
    vmware_vm_lineinfile_data: "this is line data"
  import_role:
    name:                      vmware_vm_lineinfile
~~~

## Roadmap

- mod_perms
- own_user
- own_group

- regexp support as in original [lineinfile](https://docs.ansible.com/ansible/latest/modules/lineinfile_module.html) module
