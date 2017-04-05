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
version=$(git describe --tags | sed -e "s/^v//" | cut -f1-2 -d-)

if [[ -e "/etc/redhat-release" ]]; then
   export DEPENDS="boost-date-time boost-filesystem boost-iostreams boost-signals boost-system boost-thread glibc libgcc libstatgrab libstdc++"
else
   DEPENDS="libc6 libgcc1 libstdc++6"
   ver=$(lsb_release -r -s | cut -f1 -d\.)
   if [ $ver -eq 16 ] ; then
       DEPENDS="$DEPENDS libstatgrab10"
   else
       DEPENDS="$DEPENDS libstatgrab9"
   fi
   # pick the version the packager is using ... boost versioning is derped on ubuntu
   for f in libboost-filesystem1 libboost-iostreams1 libboost-system1 libboost-thread1 ; do 
       d=$(dpkg -l | grep $f | grep -v dev | cut -c5- | cut -f1 -d:) 
       DEPENDS="$DEPENDS $d"
   done
   export DEPENDS
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
mkdir -p usr/share/istatd

cp ../istatd-server.default etc/default/istatd-server
cp ../istatd-server-init.sh etc/init.d/istatd-server
cp ../istatd-server.settings etc/istatd-server.cfg
cp ../bin/istatd usr/bin/istatd-server
cp ../README.md usr/share/doc/istatd-server
gzip usr/share/doc/istatd-server/README.md
cp -r ../files usr/share/istatd

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

fpm -s dir -t $target --name $folder_name --version ${version} --iteration $iter $(for f in $DEPENDS ; do echo --depends $f ; done) \
    --before-install ../debian/istatd-server.preinst \
    --after-install ../debian/istatd-server.postinst \
    --before-remove ../debian/istatd-server.prerm \
    --after-remove ../debian/istatd-server.postrm \
    *

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
