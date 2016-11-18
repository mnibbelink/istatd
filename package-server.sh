#!/usr/bin/env bash

set -xe
folder_name='istatd-server'

# ensure we don't bomb out later
if [ -d sandbox ] ; then
   rm -rf sandbox
fi

# only use optional ruby if system ruby is super old
if ruby --version | grep ruby.1.8 ; then 
   export PATH=/opt/ruby/2.0/bin:$PATH
fi
version=$(git describe --tags | sed -e "s/^v//")

if [[ -e "/etc/redhat-release" ]]; then
   export DEPENDS="boost-filesystem boost-iostreams boost-system boost-thread glibc libgcc libstdc++"
else
   export DEPENDS="libboost-filesystem1 libboost-iostreams1 libboost-system1 libboost-thread1 libc6 libgcc1 libstdc++6"
fi

make config
make

mkdir sandbox
cd sandbox

mkdir -p etc
mkdir -p etc/default
mkdir -p etc/init.d
mkdir -p usr/bin
mkdir -p usr/share/doc/istatd-server

cp ../istatd-server.default etc/default/istatd-server
cp ../istatd-server-init.sh etc/init.d/istatd-server
cp ../istatd-server.settings etc/istatd-server.cfg
cp ../bin/istatd usr/bin/istatd-server
cp ../README.md usr/share/doc/istatd-server
gzip usr/share/doc/istatd-server/README.md

chmod +x usr/bin/istatd-server

### Build the package

if [ -n "$BUILD_NUMBER" ]; then
    iter=$BUILD_NUMBER
else
    iter=1
fi

if [[ -e "/etc/redhat-release" ]]; then
    target=rpm
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
