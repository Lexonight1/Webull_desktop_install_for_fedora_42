#!/bin/bash
set -e

# Configuration
RELEASE="24.04"
FILENAME="Webull*.deb"
DOWNDIRDEFAULT="/home/$USER/Downloads"
TOOLBOXNAME_DEFAULT="ubuntu_toolbox"

# Validate prerequisites
if ! command -v firefox &>/dev/null; then
    echo "Error: Firefox is not installed. Please install it or use another browser."
    exit 1
fi
if ! command -v sudo &>/dev/null; then
    echo "Error: sudo is required but not installed."
    exit 1
fi

# Prompt for Webull download
echo "Please download the Linux version of Webull Desktop from https://www.webull.com/trading-platforms/desktop-app"
firefox -new-window "https://www.webull.com/trading-platforms/desktop-app" &
echo "Waiting for download to complete..."
read -p "Press Enter when the download is complete: "

# Get download directory
read -p "Enter Download Directory (default: $DOWNDIRDEFAULT): " DOWNDIR
DOWNDIR=${DOWNDIR:-$DOWNDIRDEFAULT}
if [ ! -d "$DOWNDIR" ]; then
    echo "Error: Directory '$DOWNDIR' does not exist."
    exit 1
fi

# Install Podman and Toolbox if not already installed
if ! command -v podman &>/dev/null || ! command -v toolbox &>/dev/null; then
    echo "Installing Podman and Toolbox..."
    sudo dnf install -y podman toolbox || {
        echo "Error: Failed to install Podman and Toolbox. Ensure you're on a Fedora-based system."
        exit 1
    }
fi

# Get toolbox container name
echo "Toolbox container name should use words with '_' or '-' as separators."
read -p "Name your toolbox container (default: $TOOLBOXNAME_DEFAULT): " TOOLBOXNAME
TOOLBOXNAME=${TOOLBOXNAME:-$TOOLBOXNAME_DEFAULT}
if ! [[ "$TOOLBOXNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Container name '$TOOLBOXNAME' is invalid. Use letters, numbers, '_', or '-'."
    exit 1
fi

# Check if container already exists
if toolbox list -c | grep -q "$TOOLBOXNAME"; then
    echo "Error: Toolbox container '$TOOLBOXNAME' already exists."
    exit 1
fi

# Create toolbox container
echo "Creating toolbox container named $TOOLBOXNAME..."
toolbox create --distro ubuntu --release "$RELEASE" "$TOOLBOXNAME" || {
    echo "Error: Failed to create toolbox container."
    exit 1
}

# Install dependencies in the container
echo "Updating container and installing dependencies..."
toolbox run -c "$TOOLBOXNAME" sudo apt update -y
toolbox run -c "$TOOLBOXNAME" sudo apt upgrade -y
toolbox run -c "$TOOLBOXNAME" sudo apt install -y libxrandr2 libgl1 libfontconfig1 libnss3 libasound2t64 libharfbuzz0b libthai0

# Find and validate Webull .deb file
WBDEB=$(find "$DOWNDIR" -name "$FILENAME" | head -n 1)
if [ -z "$WBDEB" ] || [ ! -f "$WBDEB" ]; then
    echo "Error: No Webull .deb file found in '$DOWNDIR'."
    exit 1
fi

# Install Webull .deb package
echo "Installing Webull Desktop from '$WBDEB'..."
toolbox run -c "$TOOLBOXNAME" sudo apt install -y "$WBDEB" || {
    echo "Error: Failed to install Webull Desktop."
    exit 1
}

# Verify Webull Desktop binary
WEBULL_BINARY="/usr/local/WebullDesktop/WebullDesktop"
if toolbox run -c "$TOOLBOXNAME" test -x "$WEBULL_BINARY"; then
    echo "Webull Desktop installed successfully."
else
    echo "Warning: Webull Desktop binary not found at '$WEBULL_BINARY'. Check the installation."
fi

# Print usage instructions
echo
echo "Toolbox container name: $TOOLBOXNAME"
echo "To run Webull Desktop: toolbox run -c $TOOLBOXNAME $WEBULL_BINARY"
echo "To remove toolbox: podman stop $TOOLBOXNAME 2>/dev/null; toolbox rm $TOOLBOXNAME"