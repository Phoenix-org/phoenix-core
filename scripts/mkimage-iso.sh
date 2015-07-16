#!/usr/bin/env bash

#
# Creates a Docker/Container Image from distro ISO file.
#

usage() {
cat <<EOOPTS
$ $(basename $0) -i <iso-image> -r <releasever> -n <image-name> [-t <target-dir>]
	OPTIONS:
	-i <iso-image>  The path to the ISO file from image is to be build.
	-r <releasever> Release version of CentOS/RHEL to be installed.
	-n <image-name> Name of image, that will be shown in docker repository.
	-t <target-dir> (Optional) Folder in which image will be exported as tar file.
EOOPTS
exit 1
}

while getopts ":i:r:n:t:h" opt; do
	case $opt in
		i)
			iso_image=$OPTARG
			;;
		r)
			releasever=$OPTARG
			;;
		n)
			image_name=$OPTARG
			;;
		t)
			target_dir=$OPTARG
			;;
		h)
			usage
			;;
		\?)
			echo "Invalid option: -$OPTARG"
			usage
			;;
	esac
done
shift $((OPTIND - 1))

if [[ -z $iso_image || -z $releasever || -z $image_name ]]; then
	usage
fi

if [ ! -x "mkimage-yum.sh" ]; then

	echo "ERROR: mkimage-yum.sh file is required in current directory with executable permission!"
	exit
fi


set -e

mount_folder=$(mktemp -d --tmpdir $(basename $0).XXXXXX)
echo "Image will be mounted at $mount_folder"

mount -o loop "$iso_image" "$mount_folder"

# Create yum.conf file.
temp_folder=$(mktemp -d --tmpdir=. $(basename temp)_XXX)
cd $temp_folder

cat << EOT >> yum.conf
[main]
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoketes=1
gogcheck=1
plugins=1
installonly_limit=5
EOT

echo "reposdir=$PWD/yum.repos.d" >> yum.conf

# Create yum.repos.d and repo file.
mkdir yum.repos.d

cat << EOT >> yum.repos.d/base.repo
[base]
name=local installation
enabled=1
EOT

echo "baseurl=file://$mount_folder" >> yum.repos.d/base.repo
cd -

# Installation using mkimage-yum script.
if [ -z "$target_dir" ]; then
	./mkimage-yum.sh -y "$temp_folder"/yum.conf -i "$image_name" -r "$releasever"
else
	./mkimage-yum.sh -y "$temp_folder"/yum.conf -i "$image_name" -r "$releasever" -t "$target_dir"
fi

# Cleanup
echo "Cleaning up of temp folders"
rm -rf "$temp_folder"
umount "$mount_folder"
rm -rf "$mount_folder"
