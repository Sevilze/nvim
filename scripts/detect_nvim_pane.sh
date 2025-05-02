#!/bin/bash
# Script to detect Neovim in the current pane

LOG_FILE="/tmp/nvim_state_save.log"
echo "===== $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"
echo "Running detect_nvim_pane.sh script" | tee -a "$LOG_FILE"

PANE_CMD=$(tmux display-message -p '#{pane_current_command}')
echo "Pane command: $PANE_CMD" | tee -a "$LOG_FILE"

if [[ "$PANE_CMD" == "nvim" || "$PANE_CMD" == "vim" ]]; then
    echo "Detected Neovim in current pane (command: $PANE_CMD)" | tee -a "$LOG_FILE"
    echo "nvim_detected" | tee -a "$LOG_FILE"
    exit 0
fi

# No Neovim found
echo "No Neovim instance found in current pane" | tee -a "$LOG_FILE"
echo "no_nvim" | tee -a "$LOG_FILE"
exit 1
