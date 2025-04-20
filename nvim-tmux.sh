#!/bin/bash

# Check if tmux is running
if ! tmux has-session 2>/dev/null; then
    # If tmux is not running, start a new session
    tmux new-session -d -s nvim
fi

# Check if we're already in a tmux session
if [ -z "$TMUX" ]; then
    # If not in a tmux session, attach to the nvim session
    tmux attach-session -t nvim
else
    # If already in a tmux session, create a new window
    tmux new-window -n "nvim" "nvim"
fi
