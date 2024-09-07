#!/bin/bash

# Variables
REPO_URL="https://github.com/aurghya-0/read-it-later"
INSTALL_DIR="$HOME/.article"
FRONTEND_DIR="$INSTALL_DIR/frontend"
SYMLINK_TARGET="/usr/local/bin/article"
EXECUTABLE_NAME="article"
REQUIREMENTS_FILE="$INSTALL_DIR/requirements.txt"
FRONTEND_START_SCRIPT="index.js"

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1 ;
}

# Clone the repository
echo "Cloning repository into $INSTALL_DIR..."
if [ -d "$INSTALL_DIR" ]; then
    echo "$INSTALL_DIR already exists, pulling latest changes..."
    git -C "$INSTALL_DIR" pull
    echo "Updating submodules..."
    git -C "$INSTALL_DIR" submodule update --init --recursive
else
    git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
fi

# Make the 'article' script executable
echo "Making $EXECUTABLE_NAME executable..."
chmod +x "$INSTALL_DIR/$EXECUTABLE_NAME"

# Create symlink
echo "Creating symlink to /usr/local/bin..."
if [ -L "$SYMLINK_TARGET" ]; then
    echo "Symlink already exists. Removing the old symlink..."
    sudo rm "$SYMLINK_TARGET"
fi

sudo ln -s "$INSTALL_DIR/$EXECUTABLE_NAME" "$SYMLINK_TARGET"

# Check if Python and pip are installed
if ! command_exists python3; then
    echo "Python3 is not installed. Please install Python3 and try again."
    exit 1
fi

if ! command_exists pip3; then
    echo "pip3 is not installed. Installing pip3..."
    sudo apt-get install -y python3-pip  # For Ubuntu/Debian. Modify this for your package manager.
fi

# Install Python requirements
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing Python dependencies from $REQUIREMENTS_FILE..."
    pip3 install -r "$REQUIREMENTS_FILE"
else
    echo "No requirements.txt file found. Skipping Python dependencies installation."
fi

# Move to frontend directory and install Node.js dependencies
if [ -d "$FRONTEND_DIR" ]; then
    echo "Installing Node.js packages in $FRONTEND_DIR..."
    cd "$FRONTEND_DIR"

    # Install npm packages
    if command_exists npm; then
        npm install
    else
        echo "npm is not installed. Please install Node.js and npm, then rerun this script."
        exit 1
    fi

    # Install pm2 globally
    echo "Installing pm2 globally..."
    sudo npm install -g pm2

    # Start the frontend app using pm2
    echo "Starting the frontend app using pm2..."
    pm2 start "$FRONTEND_DIR/$FRONTEND_START_SCRIPT"
else
    echo "Frontend directory $FRONTEND_DIR does not exist. Skipping Node.js setup."
fi

echo "Installation complete. You can now run 'article' from anywhere."
