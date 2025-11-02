#!/bin/bash

set -e  # Exit on any error

# Placeholder repository URL - replace with actual URL
REPO_URL="https://github.com/cogrow4/V-Terminal-Apps"

# List of programs to install
PROGRAMS=("tasks" "calc" "notes" "br" "quiz" "cash" "chat" "pom")

# Install V language
echo "Installing V language..."
TEMP_V_DIR=$(mktemp -d)
if ! git clone --depth=1 https://github.com/vlang/v "$TEMP_V_DIR"; then
    echo "Error: Failed to clone V repository"
    rm -rf "$TEMP_V_DIR"
    exit 1
fi
cd "$TEMP_V_DIR"
if ! make; then
    echo "Error: Failed to build V"
    cd /
    rm -rf "$TEMP_V_DIR"
    exit 1
fi
cd "$TEMP_V_DIR"

# Add V to PATH
export PATH="$TEMP_V_DIR:$PATH"

# Clone repository to temporary directory
TEMP_DIR=$(mktemp -d)
echo "Cloning repository to $TEMP_DIR..."
if ! git clone "$REPO_URL" "$TEMP_DIR"; then
    echo "Error: Failed to clone repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd "$TEMP_DIR"

# Ensure ~/bin exists and is in PATH
mkdir -p ~/bin
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "Warning: ~/bin is not in PATH. Add 'export PATH=\$PATH:\$HOME/bin' to your shell profile."
fi

# Build and install each program
for program in "${PROGRAMS[@]}"; do
    echo "Would you like to install $program? (Y/n)"
    read -r response
    response=${response:-Y}
    if [[ $response =~ ^[Yy]$ ]]; then
        echo "Building $program..."
        if [ -d "$program" ] && [ -f "$program/$program.v" ]; then
            cd "$program"
            if ! v build "$program.v"; then
                echo "Error: Failed to build $program"
                cd "$TEMP_DIR"
                continue
            fi
            mv "$program" ~/bin/ || echo "Warning: Failed to move $program to ~/bin"
            cd "$TEMP_DIR"
        elif [ -f "$program.v" ]; then
            if ! v build "$program.v"; then
                echo "Error: Failed to build $program"
                continue
            fi
            mv "$program" ~/bin/ || echo "Warning: Failed to move $program to ~/bin"
        else
            echo "Error: Source file for $program not found"
            continue
        fi
        echo "$program installed successfully"
    else
        echo "Skipping $program"
    fi
done

# Check and add ~/bin to PATH permanently
SHELL_NAME=$(basename "$SHELL")
if [[ "$SHELL_NAME" == "zsh" ]]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [[ "$SHELL_NAME" == "bash" ]]; then
    PROFILE_FILE="$HOME/.bashrc"
else
    PROFILE_FILE="$HOME/.profile"
fi
if [[ -f "$PROFILE_FILE" ]] && grep -q "export PATH.*\$HOME/bin" "$PROFILE_FILE"; then
    echo "~/bin is already in your PATH in $PROFILE_FILE."
else
    echo "export PATH=\"\$PATH:\$HOME/bin\"" >> "$PROFILE_FILE"
    echo "~/bin has been added to your PATH in $PROFILE_FILE. You may need to restart your shell or run 'source $PROFILE_FILE' for changes to take effect."
fi

# Clean up
cd /
rm -rf "$TEMP_DIR"

# Remove V language
echo "Removing V language..."
rm -rf "$TEMP_V_DIR" 2>/dev/null || true

echo "Installation complete. Programs are installed in ~/bin"