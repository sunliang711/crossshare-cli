#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
pwd=${PWD}
this="$(cd $(dirname $rpath) && pwd)"
# cd "$this"
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

# export TERM=xterm-256color

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors 2>/dev/null)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
            CYAN="$(tput setaf 5)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
            CYAN=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi
_err(){
    echo "$*" >&2
}

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

rootID=0
function _root(){
    if [ ${EUID} -ne ${rootID} ];then
        echo "Need run as root!"
        exit 1
    fi
}

ed=vi
if command -v vim >/dev/null 2>&1;then
    ed=vim
fi
if command -v nvim >/dev/null 2>&1;then
    ed=nvim
fi
if [ -n "${editor}" ];then
    ed=${editor}
fi
###############################################################################
# write your code below (just define function[s])
# function is hidden when begin with '_'
###############################################################################
#
exeName="crossshare-cli"
configName=".crossshare-cli.yaml"

install(){
    local dest="/usr/local/bin"
    _build

    _runAsRoot "mv ${this}/${exeName} ${dest}"
    cp .crossshare-cli.yaml ${home}
    echo "crossshare-cli config file: ${home}/${configName}"
}

machine="$(uname -m)"
flags="-X crossshare-cli/cmd.buildstamp=`date +%FT%T` -X crossshare-cli/cmd.githash=`git rev-parse HEAD` -X crossshare-cli/cmd.machine=${machine} -w -s"

_build(){
    cd "${this}"
    local os=${1:?'missing os'}
    local arch=${2:?'missing arch'}
    echo "build ${exeName}..."
    GOOS=${os} GOARCH=${arch} go build -ldflags "$flags" -o ${exeName} "${this}/.."
}

buildAll(){
    echo "build darwin amd64..."
    _buildTar darwin amd64
    echo "build linux amd64..."
    _buildTar linux amd64
    echo "build linux arm64..."
    _buildTar linux arm64
}

_buildTar(){
    cd "${this}"
    local os=${1:?'missing os'}
    local arch=${2:?'missing arch'}
    echo "Build for OS: ${os} Arch: ${arch}..."
    GOOS=${os} GOARCH=${arch} go build -ldflags "${flags}" -o ${exeName} "${this}/.." || { echo "failed!"; exit 1; }
    local dir="${os}-${arch}-crossshare-cli"
    mkdir "${dir}"
    mv ${exeName} ${dir}
    cp ${configName} ${dir}
    echo "Create tar file..."
    tar -jcvf "${dir}.tar.bz2" ${dir}
    /bin/rm -rf ${dir}
}

em(){
    $ed $0
}

###############################################################################
# write your code above
###############################################################################
function _help(){
    cd ${this}
    cat<<EOF2
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
EOF2
    # perl -lne 'print "\t$1" if /^\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE})
    # perl -lne 'print "\t$2" if /^\s*(function)?\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | grep -v '^\t_'
    perl -lne 'print "\t$2" if /^\s*(function)?\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | perl -lne "print if /^\t[^_]/"
}

function _loadENV(){
    if [ -z "$INIT_HTTP_PROXY" ];then
        echo "INIT_HTTP_PROXY is empty"
        echo -n "Enter http proxy: (if you need) "
        read INIT_HTTP_PROXY
    fi
    if [ -n "$INIT_HTTP_PROXY" ];then
        echo "set http proxy to $INIT_HTTP_PROXY"
        export http_proxy=$INIT_HTTP_PROXY
        export https_proxy=$INIT_HTTP_PROXY
        export HTTP_PROXY=$INIT_HTTP_PROXY
        export HTTPS_PROXY=$INIT_HTTP_PROXY
        git config --global http.proxy $INIT_HTTP_PROXY
        git config --global https.proxy $INIT_HTTP_PROXY
    else
        echo "No use http proxy"
    fi
}

function _unloadENV(){
    if [ -n "$https_proxy" ];then
        unset http_proxy
        unset https_proxy
        unset HTTP_PROXY
        unset HTTPS_PROXY
        git config --global --unset-all http.proxy
        git config --global --unset-all https.proxy
    fi
}


case "$1" in
     ""|-h|--help|help)
        _help
        ;;
    *)
        "$@"
esac
