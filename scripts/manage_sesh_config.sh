#!/bin/bash
SESH_CONFIG_DIR="$HOME/.config/sesh"
SESH_CONFIG_FILE="$SESH_CONFIG_DIR/sesh.toml"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_SESH_CONFIG="$NVIM_CONFIG_DIR/sesh.toml"

usage() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  install    - Install sesh configuration"
    echo "  update     - Update sesh configuration from nvim config"
    echo "  status     - Check status of sesh configuration"
    echo "  help       - Display this help message"
}

install_config() {
    echo "===== Sesh Configuration Installation ====="
    
    if [ ! -d "$SESH_CONFIG_DIR" ]; then
        mkdir -p "$SESH_CONFIG_DIR"
        echo "Created sesh config directory: $SESH_CONFIG_DIR"
    else
        echo "Sesh config directory already exists: $SESH_CONFIG_DIR"
    fi
    
    # Copy configuration file
    if [ -f "$NVIM_SESH_CONFIG" ]; then
        cp "$NVIM_SESH_CONFIG" "$SESH_CONFIG_FILE"
        echo "Copied sesh configuration from: $NVIM_SESH_CONFIG"
        echo "  to: $SESH_CONFIG_FILE"
    else
        echo "Error: Sesh configuration not found at: $NVIM_SESH_CONFIG"
        exit 1
    fi
    
    # Check if sesh is installed
    if command -v sesh >/dev/null 2>&1; then
        echo "Sesh is installed and available in PATH"
    elif [ -f "$HOME/go/bin/sesh" ]; then
        echo "! Sesh is installed but not in PATH"
        echo "  Run the setup script to add it to your PATH:"
        echo "  $NVIM_CONFIG_DIR/scripts/setup_sesh.sh"
    else
        echo "Sesh is not installed"
        echo "  Install it with: go install github.com/joshmedeski/sesh/v2@latest"
    fi
    
    echo "Sesh configuration installation complete!"
}

# Function to update sesh configuration
update_config() {
    echo "===== Sesh Configuration Update ====="
    
    # Check if nvim sesh config exists
    if [ ! -f "$NVIM_SESH_CONFIG" ]; then
        echo "✗ Error: Sesh configuration not found at: $NVIM_SESH_CONFIG"
        exit 1
    fi
    
    # Check if sesh config directory exists
    if [ ! -d "$SESH_CONFIG_DIR" ]; then
        mkdir -p "$SESH_CONFIG_DIR"
        echo "Created sesh config directory: $SESH_CONFIG_DIR"
    fi
    
    # Copy configuration file
    cp "$NVIM_SESH_CONFIG" "$SESH_CONFIG_FILE"
    echo "Updated sesh configuration from: $NVIM_SESH_CONFIG"
    echo "  to: $SESH_CONFIG_FILE"
    
    echo "Sesh configuration update complete!"
}

# Function to check status of sesh configuration
check_status() {
    echo "===== Sesh Configuration Status ====="
    
    # Check if sesh is installed
    if command -v sesh >/dev/null 2>&1; then
        echo "Sesh is installed and available in PATH"
        echo "  Version: $(sesh --version 2>&1)"
    elif [ -f "$HOME/go/bin/sesh" ]; then
        echo "! Sesh is installed but not in PATH"
        echo "  Run the setup script to add it to your PATH:"
        echo "  $NVIM_CONFIG_DIR/scripts/setup_sesh.sh"
    else
        echo "✗ Sesh is not installed"
        echo "  Install it with: go install github.com/joshmedeski/sesh/v2@latest"
    fi
    
    # Check if nvim sesh config exists
    if [ -f "$NVIM_SESH_CONFIG" ]; then
        echo "Nvim sesh configuration exists: $NVIM_SESH_CONFIG"
    else
        echo "✗ Nvim sesh configuration not found: $NVIM_SESH_CONFIG"
    fi
    
    # Check if sesh config directory exists
    if [ -d "$SESH_CONFIG_DIR" ]; then
        echo "Sesh config directory exists: $SESH_CONFIG_DIR"
    else
        echo "✗ Sesh config directory not found: $SESH_CONFIG_DIR"
    fi
    
    # Check if sesh config file exists
    if [ -f "$SESH_CONFIG_FILE" ]; then
        echo "Sesh configuration file exists: $SESH_CONFIG_FILE"
        
        # Compare files
        if diff -q "$NVIM_SESH_CONFIG" "$SESH_CONFIG_FILE" >/dev/null 2>&1; then
            echo "Sesh configuration is up to date"
        else
            echo "! Sesh configuration is different from nvim config"
            echo "  Run '$0 update' to update it"
        fi
    else
        echo "✗ Sesh configuration file not found: $SESH_CONFIG_FILE"
    fi
}

# Main script logic
case "$1" in
    install)
        install_config
        ;;
    update)
        update_config
        ;;
    status)
        check_status
        ;;
    help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac

exit 0
