#!/usr/bin/env bash

set -xe
folder_name='collectd-istatd'

# ensure we don't bomb out later
test ! -d sandbox

export PATH=/opt/ruby/2.0/bin:$PATH
version=$(git describe --tags)

export ROOT_DIR=`pwd`
export DEPENDS="collectd"

test -d src/collectd || mkdir -p src/collectd
pushd src/collectd
test -f collectd-4.10.9.tar.gz || curl -o collectd-4.10.9.tar.gz https://collectd.org/files/collectd-4.10.9.tar.gz
tar zxvf collectd-4.10.9.tar.gz
cd collectd-4.10.9
./configure
popd

pushd contrib/collectd
export CFLAGS="-I $ROOT_DIR/src/collectd/collectd-4.10.9/src"
make
popd

mkdir sandbox
cd sandbox

mkdir -p usr/lib/collectd

cp ../contrib/collectd/plugins/istatd.so usr/lib/collectd

### Build the package

if [ -n "$BUILD_NUMBER" ]; then
    iter=$BUILD_NUMBER
else
    iter=1
fi

if [[ -e "/etc/redhat-release" ]]; then
    target=rpm
    iter="${iter}.el6"
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
