#!/bin/bash
# Script to delete Neovim swap files
# This will be called by tmux before killing a window
# Path to Neovim swap files
SWAP_DIR="$HOME/.local/state/nvim/swap"

# Check if the swap directory exists
if [ -d "$SWAP_DIR" ]; then
    echo "Cleaning Neovim swap files..."
    find "$SWAP_DIR" -type f -name "*.swp" -delete
    find "$SWAP_DIR" -type f -name "*.swo" -delete
    echo "Swap files cleaned."
else
    echo "Swap directory not found: $SWAP_DIR"
fi
