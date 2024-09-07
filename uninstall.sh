#!/bin/bash

# Variables
INSTALL_DIR="$HOME/.article"
FRONTEND_DIR="$INSTALL_DIR/frontend"
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

# Stop and delete the pm2 process
if command_exists pm2; then
    echo "Stopping and deleting pm2 process..."
    pm2 stop "$FRONTEND_DIR/index.js" 2>/dev/null
    pm2 delete "$FRONTEND_DIR/index.js" 2>/dev/null
    echo "pm2 process stopped and deleted."
else
    echo "pm2 is not installed. Skipping pm2 cleanup."
fi

# Uninstall pm2 globally
echo "Uninstalling pm2 globally..."
if command_exists npm; then
    sudo npm uninstall -g pm2
    echo "pm2 uninstalled."
else
    echo "npm is not installed. Skipping pm2 uninstallation."
fi

# Remove Node.js dependencies
if [ -d "$FRONTEND_DIR" ]; then
    echo "Removing Node.js dependencies from $FRONTEND_DIR..."
    cd "$FRONTEND_DIR"
    if [ -f "package.json" ]; then
        rm -rf node_modules
        echo "Node.js dependencies removed."
    else
        echo "No package.json found. Skipping Node.js cleanup."
    fi
else
    echo "Frontend directory $FRONTEND_DIR does not exist."
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
