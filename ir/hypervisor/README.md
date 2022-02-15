# IR Helper Scripts to be run on the Hypervisor

The [main.sh](main.sh) script will run the following for you:

- [deps.sh](deps.sh): Install IR deps
- [git-init.sh](git-init.sh): Clone IR and configure git-review
- [venv.sh](venv.sh): pip install IR in a python virtual environment
- [clean_hypervisor.sh](clean_hypervisor.sh): Remove VMs and old .infrared directory
- [mkvms.sh](mkvms.sh): Create new virtual bare metal
- [deploy_undercloud.sh](deploy_undercloud.sh): Deploy undercloud
- [deploy_overcloud.sh](deploy_overcloud.sh): Deploy overcloud
- [tempest.sh](tempest.sh): Run tempest on overcloud
