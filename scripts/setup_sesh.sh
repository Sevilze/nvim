#!/bin/bash

# Script to set up sesh in the user's environment

# Check if sesh is already in PATH
if command -v sesh >/dev/null 2>&1; then
    echo "✓ sesh is already in your PATH"
    exit 0
fi

# Check if sesh is installed in ~/go/bin
if [ -f "$HOME/go/bin/sesh" ]; then
    echo "✓ sesh is installed in ~/go/bin"
    
    # Add to PATH in shell config files
    for config_file in ~/.bashrc ~/.zshrc; do
        if [ -f "$config_file" ]; then
            if ! grep -q "go/bin" "$config_file"; then
                echo "Adding ~/go/bin to PATH in $config_file"
                echo '# Add Go binaries to PATH' >> "$config_file"
                echo 'export PATH="$HOME/go/bin:$PATH"' >> "$config_file"
                echo "✓ Updated $config_file"
            else
                echo "✓ ~/go/bin already in PATH in $config_file"
            fi
        fi
    done
    
    # Create sesh config directory if it doesn't exist
    if [ ! -d "$HOME/.config/sesh" ]; then
        mkdir -p "$HOME/.config/sesh"
        echo "✓ Created sesh config directory"
    fi
    
    echo "✓ Setup complete! Please restart your shell or run 'source ~/.bashrc' or 'source ~/.zshrc'"
    echo "  to use sesh in your current session."
else
    echo "✗ sesh is not installed in ~/go/bin"
    echo "  Please install sesh first with: go install github.com/joshmedeski/sesh/v2@latest"
    exit 1
fi
