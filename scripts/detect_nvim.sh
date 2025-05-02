#!/bin/bash
# Script to detect Neovim in any pane of the current window

# Create a log file for debugging
LOG_FILE="/tmp/nvim_state_save.log"
echo "===== $(date '+%Y-%m-%d %H:%M:%S') =====" > "$LOG_FILE"
echo "Running detect_nvim.sh script" | tee -a "$LOG_FILE"

# Get window ID
WINDOW_ID=$(tmux display-message -p '#{window_id}')
echo "Window ID: $WINDOW_ID" | tee -a "$LOG_FILE"

# Initialize detection flag
NVIM_FOUND=0

# Check each pane for Neovim using only the most reliable method
for pane in $(tmux list-panes -t "$WINDOW_ID" -F '#{pane_index}'); do
    # Check if this pane has Neovim using pane_current_command
    PANE_CMD=$(tmux display-message -p -t "$WINDOW_ID.$pane" '#{pane_current_command}' 2>/dev/null)

    if [[ "$PANE_CMD" == "nvim" || "$PANE_CMD" == "vim" ]]; then
        echo "Found Neovim in pane $pane (command: $PANE_CMD)" | tee -a "$LOG_FILE"
        NVIM_FOUND=1
        break
    fi
done

# Return result
if [ $NVIM_FOUND -eq 1 ]; then
    echo "nvim_detected" | tee -a "$LOG_FILE"
    exit 0
else
    echo "No Neovim instance found in any pane" | tee -a "$LOG_FILE"
    echo "no_nvim" | tee -a "$LOG_FILE"
    exit 1
fi
