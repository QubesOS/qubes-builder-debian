#!/bin/sh

set -e

[ -z "$1" ] && { echo "Usage: $0 <dist>"; exit 1; }

REPO_DIR=$BUILDER_REPO_DIR
DIST=$1

mkdir -p $REPO_DIR
cd $REPO_DIR
mkdir -p dists/$DIST/main/binary-amd64
dpkg-scanpackages --multiversion . > dists/$DIST/main/binary-amd64/Packages
gzip -9c dists/$DIST/main/binary-amd64/Packages > dists/$DIST/main/binary-amd64/Packages.gz
cat > dists/$DIST/Release <<EOF
Label: Qubes builder repo
Suite: $DIST
Codename: $DIST
Date: `date -u +"%a, %d %b %Y %H:%M:%S %Z"`
Architectures: amd64
Components: main
SHA256:
EOF
calc_sha1() {
    f=dists/$DIST/$1
    echo -n " "
    echo -n `sha256sum $f|cut -d' ' -f 1` ""
    echo -n `stat -c %s $f` ""
    echo $1
}
calc_sha1 main/binary-amd64/Packages >> dists/$1/Release
calc_sha1 main/binary-amd64/Packages.gz >> dists/$1/Release

if [ `id -u` -eq 0 ]; then
    chown -R --reference=. .
fi
