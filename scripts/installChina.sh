#!/bin/bash

_runAsRoot(){
    cmd="${*}"
    local rootID=0
    if [ "${EUID}" -ne "${rootID}" ];then
        echo -n "Not root, try to run as root.."
        # or sudo sh -c ${cmd} ?
        if eval "sudo ${cmd}";then
            echo "ok"
            return 0
        else
            echo "failed"
            return 1
        fi
    else
        # or sh -c ${cmd} ?
        eval "${cmd}"
    fi
}

# ## v1.0
# darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597246/download/darwin-amd64-crossshare-cli.tar.bz2"
# ## v1.0
# linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597247/download/linux-amd64-crossshare-cli.tar.bz2"

# ## v2.0
# darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597537/download/darwin-amd64-crossshare-cli.tar.bz2"
# ## v2.0
# linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597538/download/linux-amd64-crossshare-cli.tar.bz2"

# ## v2.0.1
# darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597543/download/darwin-amd64-crossshare-cli.tar.bz2"
# ## v2.0.1
# linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597542/download/linux-amd64-crossshare-cli.tar.bz2"

# ## v2.0.2
# darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597901/download/darwin-amd64-crossshare-cli.tar.bz2"
# linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597902/download/linux-amd64-crossshare-cli.tar.bz2"

## v2.0.3
darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/598000/download/darwin-amd64-crossshare-cli.tar.bz2"
linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597999/download/linux-amd64-crossshare-cli.tar.bz2"

linuxArm64Link="https://gitee.com/sunliang711/crossshare-cli/attach_files/612986/download/linux-arm64-crossshare-cli.tar.bz2"

configName=".crossshare-cli.yaml"
exeName="crossshare-cli"

install(){
    case $(uname) in
        Darwin)
            link=${darwinLink}
        ;;
        Linux)
            link=${linuxLink}
        ;;
        *)
            echo "OS not supported."
            exit 1
        ;;
    esac

    if [ $(uname -m) = aarch64 ];then
        link=${linuxArm64Link}
    fi

    local tmpDir=/tmp/crossshare-cli-tmp-install
    if [ -d "${tmpDir}" ];then
        /bin/rm -rf "${tmpDir}"
    fi
    mkdir -p "${tmpDir}"
    cd "${tmpDir}"

    echo "Download ..."
    curl -LO ${link} || { echo "Download failed!"; exit 1; }
    tarFileName=${link##*/}
    dirName=${tarFileName%.tar.bz2}
    echo "tarFileName: ${tarFileName}"
    echo "dirName: ${dirName}"
    tar -jxvf ${tarFileName}

    cp ${dirName}/${configName} $HOME

    local dest=/usr/local/bin
    if [ ! -d "${dest}" ];then
        _runAsRoot "mkdir -p ${dest}"
    fi
    _runAsRoot "cp ${dirName}/${exeName} ${dest}" || { echo "Install failed!"; exit 1; }
    local aliasName=share
    (
        cd ${dest} && _runAsRoot "ln -sf ${exeName} ${aliasName}"
    )

    /bin/rm -rf "${tmpDir}"

    echo "config file is: $HOME/${configName}"
}

install
