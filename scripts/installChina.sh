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

# // v1.0
# darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597246/download/darwin-amd64-crossshare-cli.tar.bz2"
# // v1.0
# linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597247/download/linux-amd64-crossshare-cli.tar.bz2"

// v2.0
darwinLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597537/download/darwin-amd64-crossshare-cli.tar.bz2"
// v2.0
linuxLink="https://gitee.com/sunliang711/crossshare-cli/attach_files/597538/download/linux-amd64-crossshare-cli.tar.bz2"

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

    local tmpDir=/tmp/crossshare-cli-tmp-install
    if [ -d "${tmpDir}" ];then
        /bin/rm -rf "${tmpDir}"
    fi
    mkdir -p "${tmpDir}"
    cd "${tmpDir}"

    echo "Download ..."
    wget ${link} || { echo "Download failed!"; exit 1; }
    tarFileName=${link##*/}
    dirName=${tarFileName%.tar.bz2}
    echo "tarFileName: ${tarFileName}"
    echo "dirName: ${dirName}"
    tar -jxvf ${tarFileName}

    cp ${dirName}/${configName} $HOME
    _runAsRoot "cp ${dirName}/${exeName} /usr/local/bin" || { echo "Install failed!"; exit 1; }

    /bin/rm -rf "${tmpDir}"

    echo "config file is: $HOME/${configName}"
}

install