#!/bin/bash
# Script to delete Neovim swap files
# This will be called by tmux before killing a window

LOG_FILE="/tmp/nvim_state_save.log"
echo "===== $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"
echo "Running clean_swap_files.sh script" | tee -a "$LOG_FILE"

echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="
echo "Running swap file cleaner script" | tee -a "$LOG_FILE"

# Get current pane info
PANE_INDEX=$(tmux display-message -p '#{pane_index}')
WINDOW_ID=$(tmux display-message -p '#{window_id}')
PANE_CMD=$(tmux display-message -p '#{pane_current_command}')

echo "Pane Index: $PANE_INDEX" | tee -a "$LOG_FILE"
echo "Window ID: $WINDOW_ID" | tee -a "$LOG_FILE"
echo "Pane Command: $PANE_CMD" | tee -a "$LOG_FILE"

NVIM_IN_THIS_PANE=0
if [[ "$PANE_CMD" == "nvim" || "$PANE_CMD" == "vim" ]]; then
    echo "Detected Neovim in current pane (command: $PANE_CMD)" | tee -a "$LOG_FILE"
    NVIM_IN_THIS_PANE=1
fi

# Find a pane with Neovim if not in this pane
if [ $NVIM_IN_THIS_PANE -eq 0 ]; then
    echo "No Neovim instance in current pane. Searching other panes..." | tee -a "$LOG_FILE"
    NVIM_PANE=""

    for pane in $(tmux list-panes -t "$WINDOW_ID" -F '#{pane_index}'); do
        # Skip current pane
        if [ "$pane" = "$PANE_INDEX" ]; then
            continue
        fi

        PANE_CMD=$(tmux display-message -p -t "$WINDOW_ID.$pane" '#{pane_current_command}' 2>/dev/null)
        if [[ "$PANE_CMD" == "nvim" || "$PANE_CMD" == "vim" ]]; then
            NVIM_PANE="$pane"
            echo "Found Neovim in pane $pane (command: $PANE_CMD)" | tee -a "$LOG_FILE"
            break
        fi
    done

    if [ -z "$NVIM_PANE" ]; then
        echo "No Neovim instance found in any pane, exiting." | tee -a "$LOG_FILE"
        exit 0
    fi

    PANE_INDEX=$NVIM_PANE
fi

echo "Using Neovim in pane $PANE_INDEX" | tee -a "$LOG_FILE"

# Path to Neovim swap files
SWAP_DIR="$HOME/.local/state/nvim/swap"
echo "Swap directory path: $SWAP_DIR" | tee -a "$LOG_FILE"

# Check if the swap directory exists
if [ -d "$SWAP_DIR" ]; then
    echo "Swap directory found: $SWAP_DIR" | tee -a "$LOG_FILE"
    echo "Searching for swap files..." | tee -a "$LOG_FILE"

    SWP_COUNT=$(find "$SWAP_DIR" -type f -name "*.swp" | wc -l)
    SWO_COUNT=$(find "$SWAP_DIR" -type f -name "*.swo" | wc -l)
    TOTAL_COUNT=$((SWP_COUNT + SWO_COUNT))

    if [ $TOTAL_COUNT -gt 0 ]; then
        echo "Found $TOTAL_COUNT swap files ($SWP_COUNT .swp, $SWO_COUNT .swo)" | tee -a "$LOG_FILE"
        echo "Cleaning Neovim swap files..." | tee -a "$LOG_FILE"
        find "$SWAP_DIR" -type f -name "*.swp" -delete
        find "$SWAP_DIR" -type f -name "*.swo" -delete
        echo "Swap files cleaned successfully." | tee -a "$LOG_FILE"
    else
        echo "No swap files found, nothing to clean." | tee -a "$LOG_FILE"
    fi
else
    echo "Warning: Swap directory not found: $SWAP_DIR" | tee -a "$LOG_FILE"
fi

# Save log file path for reference
echo "" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"