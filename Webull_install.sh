#! /bin/bash
set -e
# setup environment 
### install podman and toolbox
RELEASE="24.04"
FILENAME="Webull*.deb"
DOWNDIRDEFAULT="/home/$USER/Downloads"


echo "before we start please download the linux version of webull Desktop from https://www.webull.com/trading-platforms/desktop-app"
firefox -new-window "https://www.webull.com/trading-platforms/desktop-app"  &
echo "Wait till download completes"
echo "Cool now lets setup the environment"
read -p "Enter Download Directory (default : $DOWNDIRDEFAULT): " DOWNDIR
DOWNDIR=${VALUE:-$DOWNDIRDEFAULT}
sudo dnf install -y podman toolbox
echo "toolbox container name show be words with '_' or '-' as word seperators"
read -p  "Name your toolbox container (default: ubuntu_toolbox):" TOOLBOXNAME
TOOLBOXNAME=${VALUE:-ubuntu_toolbox}
echo "creating toolbox named $TOOLBOXNAME"
toolbox create --distro ubuntu --release $RELEASE "$TOOLBOXNAME"

# install necessary debs
toolbox run -c "$TOOLBOXNAME" sudo apt update -y
toolbox run -c "$TOOLBOXNAME" sudo apt upgrade -y
toolbox run -c "$TOOLBOXNAME" sudo apt-get install libxrandr2 libgl1 libfontconfig1 libnss3 libasound2t64 libharfbuzz0b libthai0 -y

WBDEB=$(find "$DOWNDIR" -name "$FILENAME" | head -n 1)

toolbox run -c "$TOOLBOXNAME" sudo apt-get install "$WBDEB" -y


echo "toolbox container name: $TOOLBOXNAME"
echo "to run webull desktop: toolbox run -c $TOOLBOXNAME /usr/local/WebullDesktop/WebullDesktop"
echo "To remove toolbox: podman stop $TOOLBOXNAME && toolbox rm $TOOLBOXNAME"
