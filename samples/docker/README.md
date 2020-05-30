# WUcenter Dockerfile

[WUcenter](https://github.com/wucenter) project Docker image

## WUcenter framework

Currently, this repo ships Wucenter from Github master. Although, `Dockerfile` can be simply adapted to pull from Ansible Galaxy tagged releases.

[WUcenter Ansible framework](https://github.com/wucenter/wucenter-ansible) basedir is `/data/wucenter-ansible`, playbooks are installed in `/data/wucenter-ansible/books`.

### Configure

- Create local WUcenter data directories `{credentials,inventory,roles}`.

- You may use WUcenter `credentials` wizard:

``` bash
docker run -ti \
    -v credentials:/data/wucenter-ansible/credentials \
    wucenter/wucenter \
    ansible_collections/wucenter/wucenter/wucenter_creds.sh
```

- Populate `inventory` files, see example [here](https://github.com/wucenter/wucenter-ansible/tree/master/samples/inventory)

- Optional, put your custom roles to `roles`, and/or edit `roles/requirements.yml`

### Run

``` bash
docker run -ti \
    -v credentials:/data/wucenter-ansible/credentials \
    -v inventory:/data/wucenter-ansible/inventory \
    -v roles:/data/wucenter-ansible/roles \
    wucenter/wucenter \
    books/scan.yml -vv
```


## WUcenter Packer template provisioner

[WUcenter Packer template provisioner](https://github.com/wucenter/wucenter-packer) from Github master is deployed at `/data/wucenter-packer`.

### Build

You can select a different Hashicorp Packer version at build time: `--build-arg PACKER_VERSION=1.5.2`.

### Run

Edit `vcenter.json`, see example [here](https://github.com/wucenter/wucenter-packer/blob/master/samples/vcenter.json), and run:

``` bash
docker run -ti \
    -w /data/wucenter-packer \
    -v "$(pwd)"/vcenter.json:/data/wucenter-packer/config/vcenter.json \
    wucenter/wucenter \
    packer build -force -on-error=cleanup \
        -var-file=config/vcenter.json \
        -var "BUILD_DATE=$( date --rfc-3339=seconds )" \
        -var "BUILD_USER=$USER" \
        -var 'VERSION=1.1' \
        ubuntu-bionic.vcenter.json
```
