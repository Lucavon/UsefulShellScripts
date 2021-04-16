#!/bin/bash

# This script updates gitea to the latest version by checking the latest version available on its GitHub page and downloading the corresponding linux-amd64 version.
# If the script is unable to determine the latest version, you will be asked to manually enter the latest version, after which the script will continue with the automatic update.
# If you need a different version than the one for linux-amd64, adjust the download link in the line with the wget command.
# If you want to run this script unattended (which I do not recommend), you should remove the line with the read command and instead replace it with an "exit" command.
# This ensures the script does not hang if something goes wrong while running it automatically.
# Because the installed gitea version is compared to the latest one before downloading, it is (somewhat) safe to run this script regularly, as it will stop if gitea is up-to-date.
# Please keep in mind that this script only updates the binary and will not take any recommended update steps. It does not check whether the new version of gitea actually works; if a broken version of gitea is ever released, this script will still download it and, in the process, potentially break your install.  
# If you use this script, you take full responsibility for any potential damage to your system.
#
# The script needs to be run as root (not recommended) or a user with write permissions to the path where gitea's binary resides.
#
# Version history:
# V1: Initial version. Asks you to manually enter the latest version.
# V2: Automatically determines the latest version.
# V3: As a fallback, asks for the latest version if it was unable to automatically determine the latest version.
# V4: If the latest version of gitea is already installed, the script will do nothing.

echo "Determining latest gitea version..."
redir=$(curl -s -S 'https://github.com/go-gitea/gitea/releases/latest')
res=${?}
match=$(echo ${redir} | grep -P '<html><body>You are being <a href=.https:\/\/github\.com\/go-gitea\/gitea\/releases\/tag\/v.\....?.?.>redirected<\/a>\.<\/body><\/html>')
if [ "${res}" -ne 0 -o -z "${redir}" -o -z "${match}" ]; then
        echo "Failed to determine latest version: curl gave exit code ${res}, an empty redirect ('${redir}') or the response was not formed as expected (regex failed)."
        read -p 'Please manually enter the latest version of gitea (found at https://github.com/go-gitea/gitea/releases/latest):' version
else
        version=$(echo ${redir} | sed -e 's/<html><body>You are being <a href="https:\/\/github.com\/go-gitea\/gitea\/releases\/tag\/v//g' -e 's/">redirected<\/a>.<\/body><\/html>//g')
        echo "Latest gitea version is ${version}."
fi

if [ -z "${version}" ]; then
        echo "Error: Invalid version. Aborting."
        exit 1
fi

currentVer=$(gitea -v | cut -d' ' -f3)
if [ "${currentVer}" = "${version}" ]; then
        echo "Gitea ${version} is already installed. Aborting."
        exit 0
elif [ -z "${currentVer}" ]; then
        echo "Failed to determine currently installed gitea version. Aborting."
        exit 1
fi

echo "Updating to gitea version ${version}."
systemctl stop gitea
path=$(which gitea)
echo "Downloading gitea to ${path}."
wget -O giteatemp "https://dl.gitea.io/gitea/${version}/gitea-${version}-linux-amd64"

if [ "${?}" -ne 0 ]; then
        echo "Something went wrong while downloading gitea ${version}. Aborting."
        rm giteatemp
        exit 1
fi

chmod +x giteatemp
mv giteatemp "${path}"
echo "Gitea ${version} was successfully downloaded and installed."
systemctl start gitea
