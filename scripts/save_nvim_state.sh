#!/bin/bash
# Create a log file for debugging
LOG_FILE="/tmp/nvim_state_save.log"
echo "===== $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"
echo "Running save_nvim_state.sh script" >> "$LOG_FILE"

echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="
echo "Running Harpoon state save script" | tee -a "$LOG_FILE"

# Get current pane info
PANE_TTY=$(tmux display-message -p '#{pane_tty}')
PANE_INDEX=$(tmux display-message -p '#{pane_index}')
WINDOW_ID=$(tmux display-message -p '#{window_id}')
PANE_CMD=$(tmux display-message -p '#{pane_current_command}')

echo "Pane TTY: $PANE_TTY" | tee -a "$LOG_FILE"
echo "Pane Index: $PANE_INDEX" | tee -a "$LOG_FILE"
echo "Window ID: $WINDOW_ID" | tee -a "$LOG_FILE"
echo "Pane Command: $PANE_CMD" | tee -a "$LOG_FILE"

# Check if this pane has Neovim using the most reliable method
NVIM_IN_THIS_PANE=0
if [[ "$PANE_CMD" == "nvim" || "$PANE_CMD" == "vim" ]]; then
  echo "Detected Neovim in current pane (command: $PANE_CMD)" | tee -a "$LOG_FILE"
  NVIM_IN_THIS_PANE=1
fi

# Find a pane with Neovim if not in this pane
if [ $NVIM_IN_THIS_PANE -eq 0 ]; then
  echo "No Neovim instance in current pane. Searching other panes..." | tee -a "$LOG_FILE"
  NVIM_PANE=""

  # Find a pane with Neovim using the most reliable method
  for pane in $(tmux list-panes -t "$WINDOW_ID" -F '#{pane_index}'); do
    # Skip current pane
    if [ "$pane" = "$PANE_INDEX" ]; then
      continue
    fi

    # Check if this pane has Neovim
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

  # Switch to the Neovim pane for the rest of the script
  PANE_INDEX=$NVIM_PANE
fi

# If we get here, we have a Neovim pane
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")" || exit 1
echo "Working directory: $(pwd)" | tee -a "$LOG_FILE"
echo "Using Neovim in pane $PANE_INDEX" | tee -a "$LOG_FILE"

# Get current working directory and project name
CWD=$(tmux display-message -p -t "$WINDOW_ID.$PANE_INDEX" "#{pane_current_path}")
PROJECT=$(basename "$CWD")
echo "Current directory of Neovim pane: $CWD" | tee -a "$LOG_FILE"
echo "Project: $PROJECT" | tee -a "$LOG_FILE"

# Check if we're in the home directory
if [[ "$CWD" == "$HOME" ]]; then
  echo "In home directory, skipping Harpoon save" | tee -a "$LOG_FILE"
  exit 0
else
  echo "Saving Harpoon state for project: $PROJECT" | tee -a "$LOG_FILE"
  echo "Sending HarpoonSave command to Neovim in pane $PANE_INDEX..." | tee -a "$LOG_FILE"

  tmux send-keys -t "$WINDOW_ID.$PANE_INDEX" Escape ":HarpoonSave" Enter
  echo "Harpoon save command executed" | tee -a "$LOG_FILE"

  sleep 0.5
fi

# Check if the save file exists and display information
SAVE_PATH="$HOME/.local/share/nvim/harpoon/$PROJECT.json"
if [ -f "$SAVE_PATH" ]; then
  FILE_SIZE=$(du -h "$SAVE_PATH" | cut -f1)
  LAST_MODIFIED=$(stat -c %y "$SAVE_PATH")
  ITEMS=$(grep -o "value" "$SAVE_PATH" | wc -l)

  echo "" | tee -a "$LOG_FILE"
  echo "  Harpoon state saved successfully" | tee -a "$LOG_FILE"
  echo "  Save file: $SAVE_PATH" | tee -a "$LOG_FILE"
  echo "  File size: $FILE_SIZE" | tee -a "$LOG_FILE"
  echo "  Last modified: $LAST_MODIFIED" | tee -a "$LOG_FILE"
  echo "  Items in save file: $ITEMS" | tee -a "$LOG_FILE"

  if [ "$ITEMS" -eq 0 ]; then
    echo "No items found in save file. Harpoon list may be empty." | tee -a "$LOG_FILE"
  fi
else
  echo "" | tee -a "$LOG_FILE"
  echo "  Save file not found at $SAVE_PATH" | tee -a "$LOG_FILE"
  echo "  This could mean:" | tee -a "$LOG_FILE"
  echo "  - Harpoon failed to save the state" | tee -a "$LOG_FILE"
  echo "  - No files were marked in Harpoon" | tee -a "$LOG_FILE"
  echo "  - The save location is different from expected" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "===== Script completed =====" | tee -a "$LOG_FILE"

# Save log file path for reference
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"

exit 0
