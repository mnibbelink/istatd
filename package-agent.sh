#!/usr/bin/env bash

set -xe
folder_name='istatd-agent'

export PATH=/opt/python/2.7/bin:$PATH
version=$(git describe --tags)

export DEPENDS="libboost-filesystem1 libboost-iostreams1 libboost-system1 libboost-thread1 libc6 libgcc1 libstdc++6"

mkdir sandbox

cd sandbox

mkdir -p etc
mkdir -p etc/default
mkdir -p etc/init.d
mkdir -p usr/bin
mkdir -p usr/share/doc/istatd-agent

cp ../istatd-agent.default etc/default/istatd-agent
cp ../istatd-agent-init.sh etc/init.d/istatd-agent
cp ../istatd-agent.settings etc/istatd-agent.cfg
cp ../bin/istatd usr/bin/istatd-agent
cp ../README.md usr/share/doc/istatd-agent
gzip usr/share/doc/istatd-agent/README.md

chmod +x usr/bin/istatd-agent

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
