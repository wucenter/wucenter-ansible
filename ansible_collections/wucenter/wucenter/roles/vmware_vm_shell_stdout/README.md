# vmware_vm_shell_stdout

This role executes specified command on remote VM (using `vmware_vm_shell module`).

Module `vmware_vm_shell` uses VMware Guest Tools to interact with the VM out-of-band (vCenter API instead of Ansible SSH).

This role manages command's STDOUT output.
- automatically redirected to a file
- downloaded (using `vmware_guest_file_operation` module)
- optinally parsed into specified variable (YAML)
- deleted remotely (`vmware_vm_shell` module again) and locally (`file` module)

## Variables

| Variable                      | Required   | Description                                         |
| :============================ | ========== | =================================================== |
| vcenter_host                  | true       |                                                     |
| vcenter_dc                    | true       |                                                     |
| vm_username                   | true       |                                                     |
| vm_password                   | true       |                                                     |
| vm_name                       | true       |                                                     |
| vm_folder                     | true       |                                                     |
| vmware_vm_shell_stdout_bin    | true       | STRING  Command's **full** path                     |
| vmware_vm_shell_stdout_arg    | false      | STRING  Command's arguments (supports piping!)      |
| vmware_vm_shell_stdout_reg    | false      | STRING  Variable name that will receive facts       |
| vmware_vm_shell_stdout_var    | true       | STRING  Variable name that will receive stdout      |
| vmware_vm_shell_stdout_lab    | false      | STRING  Override task label                         |
| vmware_vm_shell_stdout_cro    | false      | BOOL    Read-only command, will not set `changed`   |
| vmware_vm_shell_stdout_yml    | false      | BOOL    Parse output as YAML structured             |

If the following variables are set, the role supports acting on self, ie. the ansible control host.

| Variable                      | Required   | Description                                         |
| :============================ | ========== | =================================================== |
| vm_net_ip                     | false      | IP of the VM                                        |
| controlhost_ip               | false      | IP of the ansible control host                      |

## Shell note

The `vmware_vm_shell` module accepts many shell constructs, such as multiple commands or commands
piping by forging arguments.

As `vmware_vm_shell_stdout` role appends a `>filename` redirection at the end of the arguments list,
only last command will get redirected if multiple commands are provided.

Alternatively use bash constructs: `bash -c 'cmd1 ; cmd2'`.

## Samples

### Get hostname

~~~ yaml
- import_tasks: vmware_vm_shell_stdout.yml
  vars:
    vmware_vm_shell_stdout_var: vm_hostname
    vmware_vm_shell_stdout_bin: /bin/hostname
- debug: vm_hostname
~~~

### Get several DNS infos from systemd-resolve

`awk` is used to generate a YAML-valid document.

~~~ yaml
- import_tasks: vmware_vm_shell_stdout.yml
  vars:
    vmware_vm_shell_stdout_var: vm_dns
    vmware_vm_shell_stdout_bin: /usr/bin/systemd-resolve
    vmware_vm_shell_stdout_arg: "--status eth0 | awk 'm==2{print \"vm_net_sd:\",$1 ; m=0} m==1{print \"vm_net_ns2:\",$1 ; m=0} /^[ \\t]*DNS Servers:/{m=1;print \"vm_net_ns1:\",$3} (/^[ \\t]*DNS Domain:/){m=2}'"
- debug: vm_dns
~~~
