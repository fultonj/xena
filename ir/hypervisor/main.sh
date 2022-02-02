#!/bin/bash

PRE=0
PROMPT=0
CLEAN=0
POST=0

if [ $PRE -eq 1 ]; then
    for S in deps.sh git-init.sh venv.sh clean_hypervisor.sh; do
        echo "Running $S"
        bash $S
        if [ $? -gt 0 ]; then
            echo "$S failed."
            exit 1
        fi
    done
fi

if [ $PROMPT -eq 1 ]; then
    pushd ~/infrared > /dev/null
    echo -e "$PWD has the git following branch:\n"
    git branch
    echo ""
    git log | head
    echo ""
    popd > /dev/null

    read -p "Do you want to test the above [Y/n]? " answer
    case ${answer:0:1} in
        y|Y )
            echo "Testing..."
            ;;
        * )
            exit 0
            ;;
    esac
fi

if [ $CLEAN -eq 1 ]; then
    # bash clean_hypervisor.sh
    find ~ -name .infrared -exec rm -rf {} \;
fi

if [ $POST -eq 1 ]; then
    for S in mkvms.sh deploy_undercloud.sh deploy_overcloud.sh tempest.sh; do
        echo "Running $S"
        bash $S
        if [ $? -gt 0 ]; then
            echo "$S failed."
            exit 1
        fi
    done
fi
