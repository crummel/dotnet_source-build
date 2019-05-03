#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_ROOT="$(cd -P "$( dirname "$0" )" && pwd)"
export SDK_VERSION=$(cat $SCRIPT_ROOT/DotnetCLIVersion.txt)
export SDK3_VERSION=$(cat $SCRIPT_ROOT/Dotnet3CLIVersion.txt)

if [ -z "${HOME:-}" ]; then
    export HOME="$SCRIPT_ROOT/.home"
    mkdir "$HOME"
fi

if [[ "${SOURCE_BUILD_SKIP_SUBMODULE_CHECK:-default}" == "default" || $SOURCE_BUILD_SKIP_SUBMODULE_CHECK == "0" || $SOURCE_BUILD_SKIP_SUBMODULE_CHECK == "false" ]]; then
  source "$SCRIPT_ROOT/check-submodules.sh"
fi

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_MULTILEVEL_LOOKUP=0
export NUGET_PACKAGES="$SCRIPT_ROOT/packages/"

source "$SCRIPT_ROOT/init-tools.sh"

CLIPATH="$SCRIPT_ROOT/Tools/dotnetcli"
SDKPATH="$CLIPATH/sdk/$SDK_VERSION"

# If running in Docker, make sure we have the UTF-8 locale or builds will error out.
if [ -e /.dockerenv ]; then
    if [ "$EUID" -ne "0" ]; then
        echo "error: in docker but not root, so can't fix locale"
        exit 1
    fi
    if [ -e /etc/os-release ]; then
        source /etc/os-release
        # work around a bad /etc/apt/sources.list in the image
        if [[ "$ID" == "debian" ]]; then
            printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
        fi
        if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
            apt-get update
            apt-get install -y locales
            localedef -c -i en_US -f UTF-8 en_US.UTF-8
        fi
    fi
fi

set -x

# if we are not running a RootRepo or specific target already, build Arcade first separately
if ! [[ "$@" =~ "RootRepo" || "$@" =~ "/t:" ]]; then
    $CLIPATH/dotnet $SDKPATH/MSBuild.dll /bl:arcadeBuild.binlog $SCRIPT_ROOT/build.proj /p:RootRepo=arcade "$@" /p:FailOnPrebuiltBaselineError=false
    pkill dotnet
fi
$CLIPATH/dotnet $SDKPATH/MSBuild.dll $SCRIPT_ROOT/build.proj /bl:build.binlog /flp:v=diag /clp:v=m "$@"

