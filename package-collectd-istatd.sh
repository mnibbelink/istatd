#!/usr/bin/env bash

set -xe
folder_name='collectd-istatd'

# ensure we don't bomb out later
if [ -d sandbox ] ; then
   rm -rf sandbox
fi

# only use optional ruby if system ruby is super old
if ruby --version | grep ruby.1.8 ; then 
   export PATH=/opt/ruby/2.0/bin:$PATH
fi
version=$(git describe --tags)

export ROOT_DIR=`pwd`
export DEPENDS="collectd"

if [[ -e "/etc/redhat-release" ]]; then
    plugin_dir=usr/lib64/collectd
else
    plugin_dir=usr/lib/collectd
fi

if lsb_release -d | grep Ubuntu ; then
    if ! dpkg -s collectd-dev > /dev/null ; then
	echo Please ensure collectd-dev is installed
	exit 1
    fi
else
    if lsb_release -r | grep -E "\s6\." ; then
	collectd_version=collectd-5.5.0
    else
	collectd_version=collectd-5.6.0
    fi
    test -d src/collectd || mkdir -p src/collectd
    pushd src/collectd
    test -f ${collectd_version}.tar.bz2 || curl -o ${collectd_version}.tar.bz2 https://collectd.org/files/${collect_version}.tar.bz2
    if [ ! -d ${collectd_version} ] ; then
       tar -jxvf ${collectd_version}.tar.bz2
    fi
    cd ${collectd_version}
    ./configure
    popd
    export CFLAGS="-I \"$ROOT_DIR/src/collectd/${collectd_version}/src/daemon\" -I \"$ROOT_DIR/src/collectd/${collectd_version}/src\""
fi

pushd contrib/collectd
make
popd

mkdir sandbox
cd sandbox

mkdir -p $plugin_dir

cp ../contrib/collectd/plugins/istatd.so $plugin_dir

### Build the package

if [ -n "$BUILD_NUMBER" ]; then
    iter=$BUILD_NUMBER
else
    iter=1
fi

if [[ -e "/etc/redhat-release" ]]; then
    target=rpm
    majver=$(lsb_release -rs | cut -f1 -d\. )
    iter="${iter}.el${majver}"
else
    target=deb
fi

fpm -s dir -t $target --name $folder_name --version ${version} --iteration $iter $(for f in $DEPENDS ; do echo --depends $f ; done) *

mv *.$target ..

cd ..

# if [[ "$target" == "rpm" ]]; then
#     sudo rpm --resign *.rpm
#     sudo cp *.rpm /var/repo
#     sudo createrepo --cachedir /var/repo/cache --update /var/repo
# else
#     sudo reprepro -Vb /var/repo/ includedeb $(lsb_release -cs) *.deb
# fi
rm -rf sandbox
