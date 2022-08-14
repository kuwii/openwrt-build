#!/usr/bin/env bash

CUR_DIR=$(pwd)

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

apply_commit() {
    COMMIT_ID=$1
    FILENAME="patched-$COMMIT_ID"
    if [ ! -f $FILENAME ]; then
        git cherry-pick $COMMIT_ID
        if [ $? -ne 0 ]; then
            echo "error: failed to apply commit $COMMIT_ID"
            exit 1
	fi
        echo "applied commit $COMMIT_ID" | tee $FILENAME
    fi
}

# setup openwrt repo
echo "setting up openwrt repo ..."
OPENWRT_DEST=$CUR_DIR/build/openwrt
clone_repo $OPENWRT_REPO $OPENWRT_RELEASE $OPENWRT_DEST
echo

# setup openclash repo
echo "setting up openclash repo ..."
OPENCLASH_DEST=$CUR_DIR/build/openwrt/package/luci-app-openclash
clone_repo $OPENCLASH_REPO $OPENCLASH_RELEASE $OPENCLASH_DEST
if [ -f $OPENCLASH_DEST/*.ipk ]; then
    rm $OPENCLASH_DEST/*.ipk
fi
echo

# install feeds
echo "installing feeds ..."
separate
cd $OPENWRT_DEST
./scripts/feeds update -a && ./scripts/feeds install -a
separate
if [ $? -ne 0 ]; then
    echo "error: failed install feeds"
    exit 1
fi
echo

# apply patches of some fixes
echo "applying patches ..."
separate
OPENWRT_PKG_DEST=$OPENWRT_DEST/feeds/packages
cd $OPENWRT_PKG_DEST
git fetch origin master:master
apply_commit 580926cb6ca2021190dca9918285853be4d7d4b2
separate
echo

# copy recommended config
echo "copying config ..."
cd $CUR_DIR
cp ./config/.config $OPENWRT_DEST
echo

echo "all done"
