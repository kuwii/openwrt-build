#!/usr/bin/env bash

if [ ! -f ./config/config.sh ]; then
    cp ./config/config.sh.template ./config/config.sh
fi
source ./config/config.sh

if [ $CLEANUP == 1 ]; then
    rm -rf ./build
fi
if [ ! -d ./build ]; then
    mkdir ./build
fi

separate() {
    echo "===================="
}

clone_repo() {
    REPO=$1
    BRANCH=$2
    DEST=$3
    if [ ! -d $DEST ]; then
        echo "cloning repo $REPO to $DEST ..."
        separate
        git clone --branch $BRANCH --depth 1 $REPO $DEST
        if [ $? -ne 0 ]; then
            echo "error: failed to clone repo $REPO"
            exit 1
        fi
        separate
    else
        echo "repo exists"
    fi
}

# setup openwrt repo
echo "setting up openwrt repo ..."
OPENWRT_DEST=./build/openwrt
clone_repo $OPENWRT_REPO $OPENWRT_RELEASE $OPENWRT_DEST
echo

# setup openclash repo
echo "setting up openclash repo ..."
OPENCLASH_DEST=./build/openwrt/package/luci-app-openclash
clone_repo $OPENCLASH_REPO $OPENCLASH_RELEASE $OPENCLASH_DEST
if [ -f $OPENCLASH_DEST/*.ipk ]; then
    rm $OPENCLASH_DEST/*.ipk
fi
echo

# install
echo "installing feeds ..."
cd $OPENWRT_DEST
./scripts/feeds update -a && ./scripts/feeds install -a
if [ $? -ne 0 ]; then
    echo "error: failed install feeds"
    exit 1
fi
echo

echo "all done"
