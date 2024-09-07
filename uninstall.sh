#!/bin/bash

# Variables
INSTALL_DIR="$HOME/.article"
SYMLINK_TARGET="/usr/local/bin/article"
REQUIREMENTS_FILE="$INSTALL_DIR/requirements.txt"

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1 ;
}

# Remove symlink
echo "Removing symlink from /usr/local/bin..."
if [ -L "$SYMLINK_TARGET" ]; then
    sudo rm "$SYMLINK_TARGET"
    echo "Symlink removed."
else
    echo "Symlink does not exist."
fi

# Uninstall Python dependencies if requirements.txt exists
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Uninstalling Python dependencies listed in $REQUIREMENTS_FILE..."

    # Check if pip is installed
    if command_exists pip3; then
        # Uninstall each package in requirements.txt
        pip3 uninstall -r "$REQUIREMENTS_FILE" -y
    else
        echo "pip3 is not installed. Skipping Python dependencies uninstallation."
    fi
else
    echo "No requirements.txt file found. Skipping Python dependencies uninstallation."
fi

# Remove the cloned repository
echo "Removing $INSTALL_DIR..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "Directory $INSTALL_DIR removed."
else
    echo "Directory $INSTALL_DIR does not exist."
fi

echo "Uninstallation complete."
