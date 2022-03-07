#!/usr/bin/env bash
# Clones the repos that I am interested in.
# -------------------------------------------------------
if [[ $1 == 'alias' ]]; then
    if [[ -e /home/stack/stackrc ]]; then
        echo 'source /home/stack/stackrc' >> ~/.bashrc
    fi
    echo 'alias os=openstack' >> ~/.bashrc
    echo 'alias ms=metalsmith' >> ~/.bashrc
    echo 'alias "ll=ls -lhtr"' >> ~/.bashrc
fi
# -------------------------------------------------------
if [[ $1 == 'tht' ]]; then
    declare -a repos=(
        'openstack/tripleo-heat-templates'\
        'openstack/tripleo-ansible'\
        'openstack/python-tripleoclient'\
	);
fi
# -------------------------------------------------------
if [[ $# -eq 0 ]]; then
    # uncomment whatever you want
    declare -a repos=(
                      # 'openstack/tripleo-heat-templates' \
		      # 'openstack/tripleo-common'\
                      # 'openstack/tripleo-ansible' \
                      # 'openstack/tripleo-validations' \
                      # 'openstack/python-tripleoclient' \
		      # 'openstack/puppet-ceph'\
		      # 'openstack/heat'\
		      # 'openstack-infra/tripleo-ci'\
		      # 'openstack/tripleo-puppet-elements'\
		      # 'openstack/tripleo-specs'\
		      # 'openstack/os-net-config'\
		      # 'openstack/tripleo-docs'\
		      # 'openstack/tripleo-quickstart'\
		      # 'openstack/tripleo-quickstart-extras'\
		      # 'openstack/tripleo-repos'\
		      # 'openstack/puppet-nova'\
		      # 'openstack/puppet-tripleo'\
                      # 'openstack/tripleo-operator-ansible' \
		      # add the next repo here
    );
fi
# -------------------------------------------------------
gerrit_user='fultonj'
git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple
git config --global gitreview.username $gerrit_user

git review --version
if [ $? -gt 0 ]; then
    echo "installing git-review and tox from pip"
    if [[ $(grep 8 /etc/redhat-release | wc -l) == 1 ]]; then
        if [[ ! -e /usr/bin/python3 ]]; then
            sudo dnf install python3 -y
        fi
    fi
    pip
    if [ $? -gt 0 ]; then
        V=$(python3 --version | awk {'print $2'} | awk 'BEGIN { FS = "." } ; { print $2 }')
        if [[ $V -eq "6" ]]; then
            curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
        else
            curl https://bootstrap.pypa.io/pip/get-pip.py -o get-pip.py
        fi
        python3 get-pip.py
    fi
    pip install git-review tox
fi 
pushd ~
for repo in "${repos[@]}"; do
    dir=$(echo $repo | awk 'BEGIN { FS = "/" } ; { print $2 }')
    if [ ! -d $dir ]; then
	git clone https://git.openstack.org/$repo.git
	pushd $dir
	git remote add gerrit ssh://$gerrit_user@review.openstack.org:29418/$repo.git
	git review -s
        if [ $? -gt 0 ]; then
            echo "Attempting to workaround scp error"
            cp ~/xena/workarounds/git_review/commit-msg .git/hooks/commit-msg
            chmod u+x .git/hooks/commit-msg
        fi
	popd
    else
	pushd $dir
	git pull --ff-only origin master
	popd
    fi
done
popd
# -------------------------------------------------------
if [[ $1 == 'ntp' ]]; then
    # The following change breaks my VMBC environment
    #   https://github.com/openstack/tripleo-heat-templates/commit/
    #   dfd28f7b13976a6c4f2f80cbe12c4e5476af1e0e
    # Workaround by adding this change back
    if [[ ! -e /home/stack/tripleo-heat-templates ]]; then
        echo "THT is not in home dir"
        exit 1
    fi
    pushd /home/stack/tripleo-heat-templates
    F="deployment/timesync/chrony-baremetal-ansible.yaml"
    sed -i $F -e s/'chronyc waitsync 30'/'chronyc makestep'/g
    git diff
    popd
    if [[ ! -e ~/templates ]]; then
        ln -v -s ~/tripleo-heat-templates ~/templates
    fi
fi
# -------------------------------------------------------
if [[ $1 == 'link' ]]; then
    if [[ ! -e ~/templates ]]; then
        ln -v -s ~/tripleo-heat-templates ~/templates
    fi
    # link tripleo-ansible ceph components
    if [[ -d ~/tripleo-ansible ]]; then
        # ROLES
        TARGET=/home/stack/tripleo-ansible/tripleo_ansible/roles/
        # swap out tripleo-ansible/roles/tripleo_ceph_* roles
        pushd /usr/share/ansible/roles/
        for D in tripleo_{cephadm,ceph_client,ceph_distribute_keys,run_cephadm}; do
            if [[ -d $D ]]; then
                sudo mv -v $D $D.dist
                sudo ln -v -s $TARGET/$D $D
            fi
        done
        popd
        # PLAYBOOKS
        pushd /usr/share/ansible/tripleo-playbooks/
        for F in ceph-admin-user-disable.yml ceph-admin-user-playbook.yml cephadm.yml ceph-backup.yaml ceph_deactivate_mds.yaml cli-deployed-ceph.yaml disable_cephadm.yml; do
            echo $F;
            if [[ -e $F ]]; then
                sudo mv $F $F.dist
                sudo ln -v -s /home/stack/tripleo-ansible/tripleo_ansible/playbooks/$F
            fi
        done
        popd
        # MODULES
        TARGET="/home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/modules"
        pushd /usr/share/ansible/plugins/modules
        for F in $(ls | grep ceph); do
            echo $F;
            if [[ -e $F ]]; then
                sudo mv $F $F.dist
                sudo ln -v -s $TARGET/$F
            fi
        done
        popd
        # MODULE UTILS
        TARGET="/home/stack/tripleo-ansible/tripleo_ansible/ansible_plugins/module_utils"
        pushd /usr/share/ansible/plugins/module_utils
        for F in $(ls | grep ceph); do
            echo $F;
            if [[ -e $F ]]; then
                sudo mv $F $F.dist
                sudo ln -v -s $TARGET/$F
            fi
        done
        popd
    fi
fi
# -------------------------------------------------------
