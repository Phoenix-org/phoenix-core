#!/usr/bin/env bash
#
# Create a base CentOS Docker image.
#
# This script is useful on systems with yum installed (e.g., building
# a CentOS image on CentOS).  See contrib/mkimage-rinse.sh for a way
# to build CentOS images on other systems.


usage() {
    cat <<EOOPTS
$(basename $0) [-y <yumconfig>] -i <image-name> -r <releasever> [-t <targetdir>]
OPTIONS:
  -y <yumconf>  The path to the yum config to install packages from. The
                default is /etc/yum.conf.
  -i <image-name> The name of image in docker repository.
  -r <releasever> Release version of CentOS/RHEL to be installed.
  -t <target-dir> This will export the image in this folder instead of importing image.
EOOPTS
    exit 1
}

# option defaults
yum_config=/etc/yum.conf
while getopts ":y:i:r:t:h" opt; do
    case $opt in
        y)
            yum_config=$OPTARG
            ;;
	i)
	    repo=$OPTARG
	    ;;
	r)
	    releasever=$OPTARG
	    ;;
	t)
	    targetdir=$OPTARG
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
name=$repo

if [[ -z $repo || -z $releasever ]]; then
    usage
fi


#--------------------


target=$(mktemp -d --tmpdir $(basename $0).XXXXXX)

set -e

mkdir -m 755 "$target"/dev
mknod -m 600 "$target"/dev/console c 5 1
mknod -m 600 "$target"/dev/initctl p
mknod -m 666 "$target"/dev/full c 1 7
mknod -m 666 "$target"/dev/null c 1 3
mknod -m 666 "$target"/dev/ptmx c 5 2
mknod -m 666 "$target"/dev/random c 1 8
mknod -m 666 "$target"/dev/tty c 5 0
mknod -m 666 "$target"/dev/tty0 c 4 0
mknod -m 666 "$target"/dev/urandom c 1 9
mknod -m 666 "$target"/dev/zero c 1 5

# amazon linux yum will fail without vars set
if [ -d /etc/yum/vars ]; then
	mkdir -p -m 755 "$target"/etc/yum
	cp -a /etc/yum/vars "$target"/etc/yum/
fi

yum -c "$yum_config" --quiet --installroot="$target" --releasever="$releasever" --setopt=tsflags=nodocs \
    --setopt=group_package_types=mandatory -y groupinstall Core
yum -c "$yum_config" --installroot="$target" -y clean all

cat > "$target"/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb
# --keep-services "$target".  Stolen from mkimage-rinse.sh
#  locales
rm -rf "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} > /dev/null
#  docs
rm -rf "$target"/usr/share/{man,doc,info,gnome/help} > /dev/null
#  cracklib
rm -rf "$target"/usr/share/cracklib > /dev/null
#  i18n
rm -rf "$target"/usr/share/i18n > /dev/null
#  sln
rm -rf "$target"/sbin/sln > /dev/null
#  ldconfig
rm -rf "$target"/etc/ld.so.cache > /dev/null
rm -rf "$target"/var/cache/ldconfig/* > /dev/null

version=
for file in "$target"/etc/{redhat,system}-release
do
    if [ -r "$file" ]; then
        version="$(sed 's/^[^0-9\]*\([0-9.]\+\).*$/\1/' "$file")"
        break
    fi
done

if [ -z "$version" ]; then
    echo >&2 "warning: cannot autodetect OS version, using '$name' as tag"
    version=$repo
fi

echo "$targetdir"

if [ "$targetdir" ]; then
	mkdir -p "$targetdir"
	cd "$targetdir"
	 tar --numeric-owner -c -C "$target" . > "$repo".tar > /dev/null 
	cd -
	echo "Image file is successfully build at $targetdir"
else
	tar --numeric-owner -c -C "$target" . | docker import - $repo:$version
	docker run -i -t $repo:$version echo success
	echo "Image is successfully imported in docker repository"
	echo "execute ' docker images ' to verify it"
fi

rm -rf "$target"
