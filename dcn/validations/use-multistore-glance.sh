#!/bin/bash
RC=~/control-planerc
if [[ -e $RC ]]; then
    source $RC
else
    echo "$RC is missing. abort."
    exit 1
fi

# echo "Testing import-multi-stores and copy-existing-image"
# -------------------------------------------------------
echo "- Check if glance is working"
glance image-list
if [[ $? -gt 0 ]]; then
    echo "Aborting. Not even 'glance image-list' works."
    exit 1
fi
# -------------------------------------------------------
# Get image if missing
NAME=cirros
IMG=cirros-0.4.0-x86_64-disk.img
RAW=cirros-0.4.0-x86_64-disk.raw
URL=http://download.cirros-cloud.net/0.4.0/$IMG
if [ ! -f $IMG ]; then
    echo "Could not find qemu image $img; downloading a copy."
    curl -L -# $URL > $IMG
fi
if [ ! -f $RAW ]; then
    qemu-img convert -f qcow2 -O raw $IMG $RAW
fi
# -------------------------------------------------------
OLD_ID=$(openstack image show $NAME -f value -c id)
if [[ ! -z $OLD_ID ]]; then 
    echo "- Clean out old image"
    openstack image delete $OLD_ID
fi
# -------------------------------------------------------
echo "- List available stores"
glance stores-info

echo "- Create image in central"
glance image-create \
--disk-format raw --container-format bare \
--name cirros --file $RAW \
--store central

# glance --verbose image-create-via-import --disk-format qcow2 --container-format bare --name cirros --uri $URL --import-method web-download --stores default_backend,dcn0

# STATUS=$(openstack image show $NAME -f value -c status)

ID=$(openstack image show $NAME -c id -f value)

echo "- Confirm image was converted from qcow2 to raw"
glance image-show $ID | grep disk_format

openstack image list
#bash ls_rbd.sh images

echo "Copy the image from the default store to the dcn0 and dcn1 stores:"

glance image-import $ID --stores dcn0,dcn1 --import-method copy-image
#bash ls_rbd.sh images

echo "- Show properties of $ID to see the stores"
openstack image show $ID | grep properties
