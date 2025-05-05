#!/bin/bash
# Script to manage multiple tmux-resurrect sessions
#
# NOTE: For best results, add the following line to your ~/.tmux.conf:
#   set -g @resurrect-dir "$HOME/.tmux/resurrect"
#
# This ensures tmux-resurrect always uses the same directory for saving/restoring.
#
# FEATURES:
# - Multiple named sessions can be saved and restored independently
# - Shell history isolation between sessions (enabled by default)
#   - Each pane's shell history is saved and restored with the session
#   - This prevents terminal history from overlapping between different sessions
#   - To disable, set ISOLATE_SHELL_HISTORY="false" in this script

# Ensure we have a consistent environment
export PATH="$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/$USER/.local/bin:$PATH"

# Helper function for logging
log_theme() {
    echo "$(date): $1" >> /tmp/tmux_resurrect_manager.log
}

# Helper function to debug theme colors
debug_theme_colors() {
    local theme_name="$1"
    local theme_colors="$2"

    # Create a debug file with the theme colors
    echo "Theme: $theme_name" > /tmp/tmux_theme_debug.txt
    echo "Timestamp: $(date)" >> /tmp/tmux_theme_debug.txt
    echo "Colors:" >> /tmp/tmux_theme_debug.txt
    echo "$theme_colors" >> /tmp/tmux_theme_debug.txt
}

BASE_DIR="$HOME/.tmux/resurrect/sessions"
DEFAULT_DIR="$HOME/.tmux/resurrect"
DEFAULT_SESSION="default"
RESURRECT_SCRIPTS_DIR="$HOME/.tmux/plugins/tmux-resurrect/scripts"
SESSION_INDEX_FILE="$BASE_DIR/index.txt"
HISTORY_DIR="$BASE_DIR/history"

# Configuration options
# Set to "true" to enable shell history isolation between sessions
ISOLATE_SHELL_HISTORY="true"

# Create history directory if it doesn't exist and history isolation is enabled
if [ "$ISOLATE_SHELL_HISTORY" = "true" ]; then
    mkdir -p "$HISTORY_DIR"
fi

mkdir -p "$BASE_DIR"

# Create a helper function to get hostname
get_hostname() {
    if command -v hostname >/dev/null 2>&1; then
        hostname
    elif [ -f /etc/hostname ]; then
        cat /etc/hostname
    elif [ -n "$HOSTNAME" ]; then
        echo "$HOSTNAME"
    else
        echo "unknown-host"
    fi
}

# Create a wrapper for the tmux-resurrect scripts
run_resurrect_script() {
    local script_name="$1"
    local env_vars="$2"

    # Check if the script exists
    if [ ! -f "$RESURRECT_SCRIPTS_DIR/$script_name" ]; then
        echo "Error: tmux-resurrect script not found at $RESURRECT_SCRIPTS_DIR/$script_name"
        return 1
    fi

    # Define hostname function if it doesn't exist
    if ! command -v hostname >/dev/null 2>&1; then
        hostname() {
            if [ -f /etc/hostname ]; then
                cat /etc/hostname
            elif [ -n "$HOSTNAME" ]; then
                echo "$HOSTNAME"
            else
                echo "unknown-host"
            fi
        }
        export -f hostname
    fi

    # Evaluate environment variables if provided
    if [ -n "$env_vars" ]; then
        eval "$env_vars"
    fi

    # Run the script directly
    echo "Running tmux-resurrect $script_name..."
    bash "$RESURRECT_SCRIPTS_DIR/$script_name"
    local result=$?
    return $result
}

# Function to get theme colors from NvChad
get_nvchad_colors() {
    log_theme "Theme extraction: Starting color extraction"

    # Check for exported theme colors from NvChad
    local nvchad_theme_file="$HOME/.config/tmux/theme_colors.sh"

    if [ -f "$nvchad_theme_file" ]; then
        log_theme "Theme extraction: Found exported theme colors at $nvchad_theme_file"

        # Source the theme file to get the variables
        source "$nvchad_theme_file"

        # Check if we have the required variables
        if [ -n "$HEADER_COLOR" ] && [ -n "$TEXT_COLOR" ] && [ -n "$BG_COLOR" ]; then
            log_theme "Theme extraction: Successfully loaded colors from exported file"
            log_theme "Theme extraction: Theme: $THEME_NAME, HEADER=$HEADER_COLOR, TEXT=$TEXT_COLOR, BG=$BG_COLOR"

            # Format the colors as a multi-line string
            local theme_colors=$(grep -v "^#" "$nvchad_theme_file" | grep "export" | sed 's/export //')

            # Extract theme name directly from the file for better reliability
            local theme_name=$(grep "export THEME_NAME" "$nvchad_theme_file" | cut -d'"' -f2)

            # Save theme colors to debug file
            debug_theme_colors "${theme_name:-$THEME_NAME}" "$theme_colors"

            # Return the theme colors
            echo "$theme_colors"
            return 0
        else
            log_theme "Theme extraction: Exported theme file doesn't contain required variables"
        fi
    else
        log_theme "Theme extraction: No exported theme colors found at $nvchad_theme_file"
        log_theme "Theme extraction: Please run :TmuxUpdateTheme in Neovim to export theme colors"
    fi

    # Check for NvChad config as fallback
    local chadrc_file="$HOME/.config/nvim/lua/sevilzww/chadrc.lua"
    if [ -f "$chadrc_file" ]; then
        log_theme "Theme extraction: Found NvChad config at $chadrc_file"

        # Extract theme name from chadrc.lua
        local theme_name=$(grep -o "theme = \"[^\"]*\"" "$chadrc_file" | cut -d'"' -f2)
        if [ -n "$theme_name" ]; then
            log_theme "Theme extraction: Detected theme: $theme_name"

            # Create a temporary directory for our extraction script
            local tmp_dir=$(mktemp -d)
            local lua_script="$tmp_dir/extract_colors.lua"
            local output_file="$tmp_dir/colors.txt"
            local nvim_init="$tmp_dir/init.lua"

            # Create a minimal init.lua to load NvChad
            cat > "$nvim_init" << EOF
vim.opt.rtp:prepend("$HOME/.config/nvim")
vim.cmd("set rtp+=$HOME/.local/share/nvim/lazy/base46")
EOF

            # Write the Lua script to extract colors
            cat > "$lua_script" << 'EOF'
-- Script to extract colors from NvChad's base46 module
local function extract_theme_colors()
    -- Try to load the chadrc to get the theme name
    local ok, chadrc = pcall(require, "sevilzww.chadrc")
    if not ok then
        print('# Failed to load chadrc: ' .. tostring(chadrc))
        return false
    end

    local theme_name = chadrc.base46 and chadrc.base46.theme or "tokyodark"
    print('# Theme name from chadrc: ' .. theme_name)

    -- Try to load base46
    local ok_base46, base46 = pcall(require, "base46")
    if not ok_base46 then
        print('# Failed to load base46: ' .. tostring(base46))
        return false
    end

    -- Try to load the theme colors
    local ok_colors, colors

    -- First try with get_theme_tb
    ok_colors, colors = pcall(function()
        return base46.get_theme_tb("base_30")
    end)

    if not ok_colors or not colors then
        print('# Failed to get colors with get_theme_tb: ' .. tostring(colors))

        -- Try alternative approach - load the theme directly
        ok_colors, colors = pcall(function()
            local theme_file = "base46.themes." .. theme_name
            return require(theme_file)
        end)

        if not ok_colors or not colors then
            print('# Failed to load theme directly: ' .. tostring(colors))
            return false
        end
    end

    -- Extract the colors we need
    print('# Successfully loaded colors for theme: ' .. theme_name)

    -- Map theme colors to our tmux resurrect manager colors
    local color_mapping = {
        HEADER_COLOR = colors.blue,
        ACTION_COLOR = colors.orange,
        SESSION_COLOR = colors.teal,
        TEXT_COLOR = colors.white,
        BG_COLOR = colors.black,
        BG_SELECT_COLOR = colors.darker_black or colors.black2 or colors.lightbg,
        BORDER_COLOR = colors.grey,
        PROMPT_COLOR = colors.blue,
        POINTER_COLOR = colors.blue,
        SPINNER_COLOR = colors.blue,
        INFO_COLOR = colors.blue,
        MARKER_COLOR = colors.blue,
        HL_COLOR = colors.grey,
        HL_SELECT_COLOR = colors.blue
    }

    -- Output the colors in a format that can be sourced by bash
    for name, color in pairs(color_mapping) do
        if color then
            print(name .. '="' .. color .. '"')
        else
            -- If color is nil, use a sensible default
            if name == "HEADER_COLOR" or name:match("_COLOR$") then
                print(name .. '="#7AA2F7"')  -- Default blue
            end
        end
    end

    -- Add the theme name
    print('THEME_NAME="' .. theme_name .. '"')

    return true
end

-- Run the extraction function
local ok, result = pcall(extract_theme_colors)
if not ok or result == false then
    print('# Error during extraction: ' .. tostring(result))
    print('EXTRACTION_ERROR="true"')
end
EOF

            # Execute the Lua script with a minimal Neovim setup
            log_theme "Theme extraction: Running Lua script to extract colors"

            # Try different approaches to run the script
            NVIM_APPNAME="minimal_nvim" XDG_CONFIG_HOME="$tmp_dir" nvim --headless -u "$nvim_init" -c "luafile $lua_script" -c "q" > "$output_file" 2>/dev/null

            # Check if we got any output
            if [ ! -s "$output_file" ]; then
                log_theme "Theme extraction: First attempt failed, trying with -es"
                NVIM_APPNAME="minimal_nvim" XDG_CONFIG_HOME="$tmp_dir" nvim -es -u "$nvim_init" -c "luafile $lua_script" -c "q" > "$output_file" 2>/dev/null
            fi

            # Check if we got any output
            if [ ! -s "$output_file" ]; then
                log_theme "Theme extraction: Second attempt failed, trying with standard config"
                nvim --headless -c "luafile $lua_script" -c "q" > "$output_file" 2>/dev/null
            fi

            # Log the output for debugging
            if [ -f "$output_file" ]; then
                log_theme "Theme extraction: Lua script output:"
                cat "$output_file" >> /tmp/tmux_resurrect_manager.log

                # Check if we have any errors
                if ! grep -q "EXTRACTION_ERROR" "$output_file"; then
                    # Extract the color definitions (non-comment lines)
                    local theme_colors=$(grep -v "^#" "$output_file" | grep "=" | sed 's/^//')

                    if [ -n "$theme_colors" ]; then
                        # Extract theme name if available
                        local extracted_theme=$(grep "THEME_NAME" "$output_file" | cut -d'"' -f2)
                        if [ -n "$extracted_theme" ]; then
                            theme_name="$extracted_theme"
                        fi

                        log_theme "Theme extraction: Successfully extracted colors for $theme_name"

                        # Extract some colors for logging
                        local header_color=$(grep "HEADER_COLOR" "$output_file" | cut -d'"' -f2)
                        local text_color=$(grep "TEXT_COLOR" "$output_file" | cut -d'"' -f2)
                        local bg_color=$(grep "BG_COLOR" "$output_file" | cut -d'"' -f2)

                        log_theme "Theme extraction: Dynamic colors: HEADER=$header_color, TEXT=$text_color, BG=$bg_color"

                        # Save theme colors to debug file
                        debug_theme_colors "$theme_name" "$theme_colors"

                        # Clean up
                        rm -rf "$tmp_dir"

                        # Return the theme colors
                        echo "$theme_colors"
                        return 0
                    else
                        log_theme "Theme extraction: No color values found in output"
                    fi
                else
                    log_theme "Theme extraction: Error reported by Lua script"
                fi
            else
                log_theme "Theme extraction: No output file generated"
            fi

            # Clean up if we reach here (extraction failed)
            rm -rf "$tmp_dir"
        fi
    else
        log_theme "Theme extraction: NvChad config not found"
    fi

    # If we get here, we couldn't extract the colors dynamically
    # Instead of using hardcoded fallbacks, we'll generate a basic set of colors based on the theme name
    log_theme "Theme extraction: Generating colors based on theme name: $theme_name"

    # Generate a color palette based on the theme name using a hash function
    local hash=$(echo "$theme_name" | md5sum | cut -d' ' -f1)
    local r=$(printf "%d" "0x${hash:0:2}")
    local g=$(printf "%d" "0x${hash:2:2}")
    local b=$(printf "%d" "0x${hash:4:2}")

    # Adjust to ensure colors are visible (not too dark)
    [ $r -lt 100 ] && r=$((r + 100))
    [ $g -lt 100 ] && g=$((g + 100))
    [ $b -lt 100 ] && b=$((b + 100))

    # Create hex colors
    local primary_color=$(printf "#%02X%02X%02X" $r $g $b)
    local text_color="#D8DEE9"
    local bg_color="#2E3440"
    local border_color="#4C566A"

    # Generate a dynamic color set
    local dynamic_colors="
HEADER_COLOR=\"$primary_color\"
ACTION_COLOR=\"#$(printf "%02X%02X%02X" $((g)) $((r)) $((b)))\"
SESSION_COLOR=\"#$(printf "%02X%02X%02X" $((b)) $((g)) $((r)))\"
TEXT_COLOR=\"$text_color\"
BG_COLOR=\"$bg_color\"
BG_SELECT_COLOR=\"#$(printf "%02X%02X%02X" $((40)) $((50)) $((70)))\"
BORDER_COLOR=\"$border_color\"
PROMPT_COLOR=\"$primary_color\"
POINTER_COLOR=\"$primary_color\"
SPINNER_COLOR=\"$primary_color\"
INFO_COLOR=\"$primary_color\"
MARKER_COLOR=\"$primary_color\"
HL_COLOR=\"$border_color\"
HL_SELECT_COLOR=\"$primary_color\"
THEME_NAME=\"$theme_name (generated)\"
"

    log_theme "Theme extraction: Generated dynamic colors: PRIMARY=$primary_color, TEXT=$text_color, BG=$bg_color"
    debug_theme_colors "$theme_name (generated)" "$dynamic_colors"

    echo "$dynamic_colors"
}


find_latest_session() {
    local latest_file=$(ls -t "$DEFAULT_DIR"/tmux_resurrect_*.txt 2>/dev/null | head -n 1)
    if [ -n "$latest_file" ]; then
        echo "Latest session file: $latest_file" >> /tmp/tmux_resurrect_manager.log
        echo "$latest_file"
    else
        echo ""
    fi
}

# Function to save shell history for each pane
save_shell_history() {
    local session_name="$1"

    # Skip if history isolation is disabled
    if [ "$ISOLATE_SHELL_HISTORY" != "true" ]; then
        echo "$(date): Shell history isolation is disabled, skipping" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    if [ -z "$session_name" ] || [ "$session_name" = "default" ]; then
        # Don't save history for default sessions
        echo "$(date): Not saving history for default session" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    echo "$(date): Saving shell history for session: $session_name" >> /tmp/tmux_resurrect_manager.log

    # Create session history directory
    local history_session_dir="$HISTORY_DIR/$session_name"
    mkdir -p "$history_session_dir"
    echo "$(date): Created history directory: $history_session_dir" >> /tmp/tmux_resurrect_manager.log

    # Get all panes
    local pane_count=0
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}" | while read -r pane_info; do
        local pane_id=$(echo "$pane_info" | awk '{print $1}')
        local pane_pid=$(echo "$pane_info" | awk '{print $2}')

        # Skip if not in the current session
        if [[ "$pane_id" != "$session_name:"* ]]; then
            continue
        fi

        pane_count=$((pane_count + 1))
        echo "$(date): Processing pane $pane_id (PID: $pane_pid)" >> /tmp/tmux_resurrect_manager.log

        # Get the shell PID (child of the pane process)
        local shell_pid=$(pgrep -P "$pane_pid" -f "bash|zsh|fish|sh" 2>/dev/null | head -1)
        if [ -z "$shell_pid" ]; then
            shell_pid="$pane_pid"
            echo "$(date): No shell process found, using pane PID: $shell_pid" >> /tmp/tmux_resurrect_manager.log
        else
            echo "$(date): Found shell process with PID: $shell_pid" >> /tmp/tmux_resurrect_manager.log
        fi

        # Create a unique identifier for this pane
        local pane_identifier=$(echo "$pane_id" | tr ':.' '_')
        local history_file="$history_session_dir/${pane_identifier}.history"
        echo "$(date): History file will be: $history_file" >> /tmp/tmux_resurrect_manager.log

        # Save the history for this pane
        if [ -n "$shell_pid" ]; then
            # Try to get the shell type
            local shell_type=$(ps -p "$shell_pid" -o comm= 2>/dev/null | sed 's/^-//')
            echo "$(date): Detected shell type: $shell_type" >> /tmp/tmux_resurrect_manager.log

            # Create a temporary script to save history
            local tmp_script=$(mktemp)
            echo "$(date): Created temporary script: $tmp_script" >> /tmp/tmux_resurrect_manager.log

            if [[ "$shell_type" == *"bash"* ]]; then
                # For Bash
                cat > "$tmp_script" << EOF
#!/bin/bash
# Save bash history
history -a
history > "$history_file" 2>/dev/null
echo "History saved to $history_file with \$(wc -l < "$history_file" 2>/dev/null || echo 0) lines"
sleep 1
EOF
            elif [[ "$shell_type" == *"zsh"* ]]; then
                # For Zsh
                cat > "$tmp_script" << EOF
#!/bin/zsh
# Save zsh history
fc -W "$history_file" 2>/dev/null || history > "$history_file" 2>/dev/null
echo "History saved to $history_file with \$(wc -l < "$history_file" 2>/dev/null || echo 0) lines"
sleep 1
EOF
            elif [[ "$shell_type" == *"fish"* ]]; then
                # For Fish
                cat > "$tmp_script" << EOF
#!/usr/bin/env fish
# Save fish history
history save
history > "$history_file" 2>/dev/null
echo "History saved to $history_file with \$(wc -l < "$history_file" 2>/dev/null || echo 0) lines"
sleep 1
EOF
            else
                # Generic fallback
                cat > "$tmp_script" << EOF
#!/bin/sh
# Save shell history (generic)
history > "$history_file" 2>/dev/null
echo "History saved to $history_file with \$(wc -l < "$history_file" 2>/dev/null || echo 0) lines"
sleep 1
EOF
            fi

            chmod +x "$tmp_script"

            # Execute the script in the pane
            tmux send-keys -t "$pane_id" C-u
            tmux send-keys -t "$pane_id" "source $tmp_script" C-m

            # Wait for script to complete
            sleep 2

            # Clean up
            rm -f "$tmp_script"

            # Check if history file was created and has content
            if [ -f "$history_file" ]; then
                local line_count=$(wc -l < "$history_file" 2>/dev/null || echo 0)
                echo "$(date): Saved history for pane $pane_id (shell: $shell_type) with $line_count lines" >> /tmp/tmux_resurrect_manager.log
            else
                echo "$(date): WARNING: Failed to create history file for pane $pane_id" >> /tmp/tmux_resurrect_manager.log
            fi
        fi
    done

    # Give a moment for history files to be written
    sleep 2

    # Check if any history files were created
    local file_count=$(find "$history_session_dir" -type f -name "*.history" | wc -l)
    echo "$(date): Created $file_count history files for session $session_name" >> /tmp/tmux_resurrect_manager.log

    return 0
}

# Function to restore shell history for each pane
restore_shell_history() {
    local session_name="$1"

    # Skip if history isolation is disabled
    if [ "$ISOLATE_SHELL_HISTORY" != "true" ]; then
        echo "$(date): Shell history isolation is disabled, skipping restoration" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    if [ -z "$session_name" ] || [ "$session_name" = "default" ]; then
        # Don't restore history for default sessions
        echo "$(date): Not restoring history for default session" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    echo "$(date): Restoring shell history for session: $session_name" >> /tmp/tmux_resurrect_manager.log

    # Check if session history directory exists
    local history_session_dir="$HISTORY_DIR/$session_name"
    if [ ! -d "$history_session_dir" ]; then
        echo "$(date): No history directory found for session: $session_name" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    # Check if there are any history files
    local history_files=$(find "$history_session_dir" -type f -name "*.history" 2>/dev/null)
    if [ -z "$history_files" ]; then
        echo "$(date): No history files found in directory: $history_session_dir" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    echo "$(date): Found history files in $history_session_dir" >> /tmp/tmux_resurrect_manager.log

    # Wait a moment for panes to be fully restored
    sleep 3

    # Get all panes
    local pane_count=0
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}" | while read -r pane_info; do
        local pane_id=$(echo "$pane_info" | awk '{print $1}')
        local pane_pid=$(echo "$pane_info" | awk '{print $2}')

        # Skip if not in the current session
        if [[ "$pane_id" != "$session_name:"* ]]; then
            continue
        fi

        pane_count=$((pane_count + 1))
        echo "$(date): Processing pane $pane_id (PID: $pane_pid) for history restoration" >> /tmp/tmux_resurrect_manager.log

        # Create a unique identifier for this pane
        local pane_identifier=$(echo "$pane_id" | tr ':.' '_')
        local history_file="$history_session_dir/${pane_identifier}.history"

        # Check if history file exists
        if [ -f "$history_file" ]; then
            echo "$(date): Found history file: $history_file" >> /tmp/tmux_resurrect_manager.log

            # Get the shell type
            local shell_pid=$(pgrep -P "$pane_pid" -f "bash|zsh|fish|sh" 2>/dev/null | head -1)
            if [ -z "$shell_pid" ]; then
                shell_pid="$pane_pid"
                echo "$(date): No shell process found, using pane PID: $shell_pid" >> /tmp/tmux_resurrect_manager.log
            else
                echo "$(date): Found shell process with PID: $shell_pid" >> /tmp/tmux_resurrect_manager.log
            fi

            local shell_type=$(ps -p "$shell_pid" -o comm= 2>/dev/null | sed 's/^-//')
            echo "$(date): Detected shell type: $shell_type" >> /tmp/tmux_resurrect_manager.log

            # Create a temporary script to restore history
            local tmp_script=$(mktemp)
            echo "$(date): Created temporary script: $tmp_script" >> /tmp/tmux_resurrect_manager.log

            if [[ "$shell_type" == *"bash"* ]]; then
                # For Bash
                cat > "$tmp_script" << EOF
#!/bin/bash
# Restore bash history
if [ -f "$history_file" ]; then
    line_count=\$(wc -l < "$history_file" 2>/dev/null || echo 0)
    echo "Restoring \$line_count lines of history from $history_file"
    cat "$history_file" | tail -n 1000 > ~/.bash_history_temp
    mv ~/.bash_history_temp ~/.bash_history
    history -c
    history -r
    echo "History restored successfully"
else
    echo "History file not found: $history_file"
fi
sleep 1
EOF
            elif [[ "$shell_type" == *"zsh"* ]]; then
                # For Zsh
                cat > "$tmp_script" << EOF
#!/bin/zsh
# Restore zsh history
if [ -f "$history_file" ]; then
    line_count=\$(wc -l < "$history_file" 2>/dev/null || echo 0)
    echo "Restoring \$line_count lines of history from $history_file"
    cat "$history_file" | tail -n 1000 > ~/.zsh_history_temp
    mv ~/.zsh_history_temp ~/.zsh_history
    fc -R ~/.zsh_history
    echo "History restored successfully"
else
    echo "History file not found: $history_file"
fi
sleep 1
EOF
            elif [[ "$shell_type" == *"fish"* ]]; then
                # For Fish
                cat > "$tmp_script" << EOF
#!/usr/bin/env fish
# Restore fish history
if [ -f "$history_file" ]
    set line_count (wc -l < "$history_file" 2>/dev/null || echo 0)
    echo "Restoring \$line_count lines of history from $history_file"
    cat "$history_file" > ~/.local/share/fish/fish_history_temp
    mv ~/.local/share/fish/fish_history_temp ~/.local/share/fish/fish_history
    echo "History restored successfully"
else
    echo "History file not found: $history_file"
end
sleep 1
EOF
            else
                # Generic fallback
                cat > "$tmp_script" << EOF
#!/bin/sh
# Restore shell history (generic)
if [ -f "$history_file" ]; then
    line_count=\$(wc -l < "$history_file" 2>/dev/null || echo 0)
    echo "Restoring \$line_count lines of history from $history_file"
    cat "$history_file" > ~/.history_temp
    mv ~/.history_temp ~/.history
    history -c
    history -r 2>/dev/null || true
    echo "History restored successfully"
else
    echo "History file not found: $history_file"
fi
sleep 1
EOF
            fi

            chmod +x "$tmp_script"

            # Execute the script in the pane
            tmux send-keys -t "$pane_id" C-u
            tmux send-keys -t "$pane_id" "source $tmp_script" C-m

            # Wait for script to complete
            sleep 2

            # Clean up
            rm -f "$tmp_script"

            echo "$(date): Restored history for pane $pane_id (shell: $shell_type)" >> /tmp/tmux_resurrect_manager.log
        else
            echo "$(date): No history file found for pane $pane_id: $history_file" >> /tmp/tmux_resurrect_manager.log
        fi
    done

    echo "$(date): Processed $pane_count panes for history restoration" >> /tmp/tmux_resurrect_manager.log

    return 0
}

# Function to update the session index
update_session_index() {
    local session_name="$1"
    local session_file="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    if [ ! -f "$SESSION_INDEX_FILE" ]; then
        echo "# Tmux Session Index" > "$SESSION_INDEX_FILE"
        echo "# name | file | timestamp" >> "$SESSION_INDEX_FILE"
        echo "# ---------------------------" >> "$SESSION_INDEX_FILE"
    fi

    # Check if session already exists in index
    if grep -q "^$session_name|" "$SESSION_INDEX_FILE"; then
        # Remove existing entry first
        sed -i "\|^$session_name|d" "$SESSION_INDEX_FILE"
    fi

    # Add new entry
    echo "$session_name|$session_file|$timestamp" >> "$SESSION_INDEX_FILE"
    echo "$(date): Updated index for session: $session_name -> $session_file" >> /tmp/tmux_resurrect_manager.log
}

# Log script execution for debugging
echo "$(date): tmux_resurrect_manager.sh executed with args: $@" >> /tmp/tmux_resurrect_manager.log
list_sessions() {
    local format_mode="$1"

    # Format for display in terminal
    if [ "$format_mode" != "json" ]; then
        echo "===== Current Tmux State ====="
        echo "Current tmux server information:"
        tmux info 2>/dev/null | grep -E "socket|server|clients|sessions" | sed 's/^/  /'

        echo -e "\nActive sessions:"
        tmux list-sessions 2>/dev/null | sed 's/^/  /' || echo "  No active sessions"

        echo -e "\n===== Available Custom Sessions ====="
        if [ -f "$SESSION_INDEX_FILE" ]; then
            # Adjust column widths for better fit
            echo "  NAME                 | SAVED AT                  | WIN | PANE"
            echo "  ---------------------|---------------------------|-----|------"
            grep -v "^#" "$SESSION_INDEX_FILE" | while IFS="|" read -r name file timestamp; do
                if [ -n "$name" ] && [ -n "$file" ]; then
                    # Get window and pane count
                    local window_count="?"
                    local pane_count="?"
                    if [ -f "${file}.meta" ]; then
                        window_count=$(grep -c "^# - .*:[0-9]*:.* ([0-9]* panes)" "${file}.meta" 2>/dev/null | wc -l | awk '{print $1}')
                        pane_count=$(grep -c "^# - .*:[0-9]*\.[0-9]* \[" "${file}.meta" 2>/dev/null || echo "?")
                        # Fallback if counts are zero or failed
                        [ "$window_count" = "0" ] && window_count="?"
                        [ "$pane_count" = "0" ] && pane_count="?"
                    fi
                    # Adjusted printf format
                    printf "  %-20s | %-25s | %-3s | %-4s\n" "$name" "$timestamp" "$window_count" "$pane_count"
                fi
            done
        else
            local custom_sessions=$(ls -1 "$BASE_DIR" 2>/dev/null | grep -v "index.txt" | sed 's/\.txt$//')
            if [ -n "$custom_sessions" ]; then
                echo "$custom_sessions" | sed 's/^/  /'
            else
                echo "  No custom sessions found."
            fi
        fi

        echo -e "\n===== Default tmux-resurrect Sessions ====="
        local default_sessions=$(ls -1t "$DEFAULT_DIR"/tmux_resurrect_*.txt 2>/dev/null | sed 's|.*/tmux_resurrect_||' | sed 's/\.txt$//')
        if [ -n "$default_sessions" ]; then
            echo "  TIMESTAMP            | DATE/TIME"
            echo "  ---------------------|-------------------------"
            echo "$default_sessions" | head -5 | while read -r timestamp; do
                local date_display=$(echo "$timestamp" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
                printf "  %-20s | %s\n" "$timestamp" "$date_display"
            done

            if [ "$(echo "$default_sessions" | wc -l)" -gt 5 ]; then
                echo "  ... ($(echo "$default_sessions" | wc -l) total sessions)"
            fi
            echo -e "\n  Latest session: $(basename "$(find_latest_session)" 2>/dev/null)"
        else
            echo "  No default sessions found."
        fi

        echo -e "\nUsage:"
        echo "  - Use 'default' to restore the latest session"
        echo "  - Use a custom name to restore a named session"
        echo "  - Use a timestamp (YYYYMMDDTHHMMSS) to restore a specific default session"
    else
        echo "{"
        echo "  \"active_sessions\": ["
        local first=true
        tmux list-sessions -F "#{session_name}" 2>/dev/null | while read -r session; do
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    \"$session\""
        done
        echo "  ],"

        echo "  \"custom_sessions\": ["
        first=true
        if [ -f "$SESSION_INDEX_FILE" ]; then
            grep -v "^#" "$SESSION_INDEX_FILE" | while IFS="|" read -r name file timestamp; do
                if [ -n "$name" ] && [ -n "$file" ]; then
                    if [ "$first" = true ]; then
                        first=false
                    else
                        echo ","
                    fi
                    echo "    {"
                    echo "      \"name\": \"$name\","
                    echo "      \"file\": \"$file\","
                    echo "      \"timestamp\": \"$timestamp\""
                    echo "    }"
                fi
            done
        fi
        echo "  ],"

        echo "  \"default_sessions\": ["
        first=true
        ls -1t "$DEFAULT_DIR"/tmux_resurrect_*.txt 2>/dev/null | sed 's|.*/tmux_resurrect_||' | sed 's/\.txt$//' | while read -r timestamp; do
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    \"$timestamp\""
        done
        echo "  ],"

        echo "  \"latest_session\": \"$(basename "$(find_latest_session)" 2>/dev/null)\""
        echo "}"
    fi
}

save_session() {
    local session_name="$1"
    if [ -z "$session_name" ]; then
        session_name="$DEFAULT_SESSION"
    fi

    echo "$(date): Attempting to save session: $session_name" >> /tmp/tmux_resurrect_manager.log

    if ! tmux info &>/dev/null; then
        echo "Error: tmux is not running"
        echo "$(date): Error - tmux is not running" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    if [ ! -d "$RESURRECT_SCRIPTS_DIR" ]; then
        echo "Error: tmux-resurrect scripts directory not found at $RESURRECT_SCRIPTS_DIR"
        echo "$(date): Error - tmux-resurrect scripts directory not found" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    if [ ! -f "$RESURRECT_SCRIPTS_DIR/save.sh" ]; then
        echo "Error: tmux-resurrect save script not found at $RESURRECT_SCRIPTS_DIR/save.sh"
        echo "$(date): Error - tmux-resurrect save script not found" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    local tmux_info=$(tmux info 2>/dev/null)
    local active_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
    local active_windows=$(tmux list-windows -a -F "#{session_name}:#{window_index}:#{window_name}" 2>/dev/null)

    local temp_file=$(mktemp)

    # Always save to the default location first
    run_resurrect_script "save.sh" ""
    local save_result=$?
    local latest_file=$(find_latest_session)

    if [ $save_result -ne 0 ] || [ -z "$latest_file" ]; then
        echo "Error: Failed to save session"
        echo "$(date): Error - Failed to save session (exit code: $save_result)" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    if [ "$session_name" = "default" ]; then
        echo "Session saved as default: $(basename "$latest_file")"
        echo "$(date): Successfully saved default session: $latest_file" >> /tmp/tmux_resurrect_manager.log
        update_session_index "default" "$latest_file"
    else
        local custom_file="$BASE_DIR/${session_name}.txt"

        # Copy the latest file to our custom location
        cp "$latest_file" "$custom_file" 2>/dev/null
        local copy_result=$?

        # Clean up any temporary files
        rm -f "$temp_file" 2>/dev/null

        if [ $copy_result -eq 0 ]; then
            echo "Session saved as: $session_name"
            echo "$(date): Successfully saved session: $session_name" >> /tmp/tmux_resurrect_manager.log
            echo "$(date): Copied $latest_file to $custom_file" >> /tmp/tmux_resurrect_manager.log

            # Update the "last" symlink to point to our custom file
            ln -sf "$custom_file" "$DEFAULT_DIR/last"
            echo "$(date): Updated 'last' symlink to point to: $custom_file" >> /tmp/tmux_resurrect_manager.log

            # Update the index
            update_session_index "$session_name" "$custom_file"

            # Save shell history for this session
            save_shell_history "$session_name"

            echo "# Tmux session: $session_name" > "$custom_file.meta"
            echo "# Saved at: $(date)" >> "$custom_file.meta"
            echo "# Active sessions: $active_sessions" >> "$custom_file.meta"

            echo "# Active windows:" >> "$custom_file.meta"
            tmux list-windows -a -F "# - #{session_name}:#{window_index}:#{window_name} (#{window_panes} panes)" >> "$custom_file.meta"

            echo "# Active panes:" >> "$custom_file.meta"
            tmux list-panes -a -F "# - #{session_name}:#{window_index}.#{pane_index} [#{pane_width}x#{pane_height}] #{?pane_active,(active),}" >> "$custom_file.meta"

            echo "# Pane working directories:" >> "$custom_file.meta"
            tmux list-panes -a -F "# - #{session_name}:#{window_index}.#{pane_index}: #{pane_current_path}" >> "$custom_file.meta"

            echo "# Pane processes:" >> "$custom_file.meta"
            tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" | while read -r pane_id; do
                local pane_pid=$(tmux display-message -p -t "$pane_id" "#{pane_pid}" 2>/dev/null)
                if [ -n "$pane_pid" ]; then
                    echo "# - $pane_id: $(ps -o comm= -p $pane_pid 2>/dev/null || echo "unknown")" >> "$custom_file.meta"
                fi
            done
        else
            echo "Error: Failed to save session: $session_name"
            echo "$(date): Error - Failed to save session: $session_name (exit code: $save_result)" >> /tmp/tmux_resurrect_manager.log
        fi
    fi

    return $save_result
}

restore_session() {
    local session_name="$1"
    if [ -z "$session_name" ]; then
        session_name="$DEFAULT_SESSION"
    fi

    echo "$(date): Attempting to restore session: $session_name" >> /tmp/tmux_resurrect_manager.log

    if ! tmux info &>/dev/null; then
        echo "Error: tmux is not running"
        echo "$(date): Error - tmux is not running" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    if [ ! -d "$RESURRECT_SCRIPTS_DIR" ]; then
        echo "Error: tmux-resurrect scripts directory not found at $RESURRECT_SCRIPTS_DIR"
        echo "$(date): Error - tmux-resurrect scripts directory not found" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    if [ ! -f "$RESURRECT_SCRIPTS_DIR/restore.sh" ]; then
        echo "Error: tmux-resurrect restore script not found at $RESURRECT_SCRIPTS_DIR/restore.sh"
        echo "$(date): Error - tmux-resurrect restore script not found" >> /tmp/tmux_resurrect_manager.log
        return 1
    fi

    local session_file=""
    local restore_path=""

    if [ -f "$SESSION_INDEX_FILE" ] && [ "$session_name" != "default" ] && ! [[ "$session_name" =~ ^[0-9]{8}T[0-9]{6}$ ]]; then
        local indexed_file=$(grep "^$session_name|" "$SESSION_INDEX_FILE" | cut -d'|' -f2)
        if [ -n "$indexed_file" ] && [ -f "$indexed_file" ]; then
            session_file="$indexed_file"
            restore_path="$indexed_file"
            echo "Using indexed session: $indexed_file" >> /tmp/tmux_resurrect_manager.log
        fi
    fi

    if [ -z "$session_file" ]; then
        # If session name is "default", use the latest tmux-resurrect session
        if [ "$session_name" = "default" ]; then
            session_file=$(find_latest_session)
            if [ -n "$session_file" ] && [ -f "$session_file" ]; then
                restore_path="$session_file"
                echo "Using latest tmux-resurrect session: $session_file" >> /tmp/tmux_resurrect_manager.log
            else
                echo "Error: No default session found."
                echo "$(date): Error - No default session found" >> /tmp/tmux_resurrect_manager.log
                list_sessions
                return 1
            fi
        # Check if it's a timestamp-based session in the default directory
        elif [[ "$session_name" =~ ^[0-9]{8}T[0-9]{6}$ ]]; then
            session_file="$DEFAULT_DIR/tmux_resurrect_${session_name}.txt"
            if [ -f "$session_file" ]; then
                restore_path="$session_file"
                echo "Using timestamp-based session: $session_file" >> /tmp/tmux_resurrect_manager.log
            else
                echo "Error: Session '$session_name' not found."
                echo "$(date): Error - Session file not found: $session_file" >> /tmp/tmux_resurrect_manager.log
                list_sessions
                return 1
            fi
        else
            session_file="$BASE_DIR/${session_name}.txt"
            if [ -f "$session_file" ]; then
                restore_path="$session_file"
                echo "Using custom session: $session_file" >> /tmp/tmux_resurrect_manager.log
            else
                echo "Error: Session '$session_name' not found."
                echo "$(date): Error - Session file not found: $session_file" >> /tmp/tmux_resurrect_manager.log
                list_sessions
                return 1
            fi
        fi
    fi

    if [ -f "${session_file}.meta" ]; then
        echo "Session metadata:"
        cat "${session_file}.meta"
    fi

    # Update the "last" symlink in the default directory to point to our session file
    # This ensures tmux-resurrect will use our file regardless of environment variables
    if [ -f "$restore_path" ]; then
        # Create a symlink to our session file
        ln -sf "$restore_path" "$DEFAULT_DIR/last"
        echo "$(date): Updated 'last' symlink to point to: $restore_path" >> /tmp/tmux_resurrect_manager.log
    fi

    # Execute the restore script (without custom path - it will use the "last" symlink)
    run_resurrect_script "restore.sh" ""
    local restore_result=$?

    if [ $restore_result -eq 0 ]; then
        echo "Session restored: $session_name"
        echo "$(date): Successfully restored session: $session_name" >> /tmp/tmux_resurrect_manager.log

        # Restore shell history for this session
        restore_shell_history "$session_name"

        local first_session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | head -1)
        if [ -n "$first_session" ]; then
            tmux switch-client -t "$first_session" 2>/dev/null || true
        fi
    else
        echo "Error: Failed to restore session: $session_name"
        echo "$(date): Error - Failed to restore session: $session_name (exit code: $restore_result)" >> /tmp/tmux_resurrect_manager.log
    fi

    return $restore_result
}

delete_session() {
    local session_name="$1"
    if [ -z "$session_name" ]; then
        echo "Error: Please specify a session name to delete."
        echo "$(date): Error - No session name specified for deletion" >> /tmp/tmux_resurrect_manager.log
        list_sessions
        return 1
    fi

    echo "$(date): Attempting to delete session: $session_name" >> /tmp/tmux_resurrect_manager.log

    local session_file=""
    local found=false

    if [ -f "$SESSION_INDEX_FILE" ] && [ "$session_name" != "default" ] && ! [[ "$session_name" =~ ^[0-9]{8}T[0-9]{6}$ ]]; then
        local indexed_file=$(grep "^$session_name|" "$SESSION_INDEX_FILE" | cut -d'|' -f2)
        if [ -n "$indexed_file" ] && [ -f "$indexed_file" ]; then
            session_file="$indexed_file"
            found=true

            # Remove from index
            grep -v "^$session_name|" "$SESSION_INDEX_FILE" > "${SESSION_INDEX_FILE}.tmp"
            mv "${SESSION_INDEX_FILE}.tmp" "$SESSION_INDEX_FILE"
            echo "Removed session '$session_name' from index" >> /tmp/tmux_resurrect_manager.log
        fi
    fi

    if [ "$found" = false ]; then
        if [[ "$session_name" =~ ^[0-9]{8}T[0-9]{6}$ ]]; then
            session_file="$DEFAULT_DIR/tmux_resurrect_${session_name}.txt"
            if [ -f "$session_file" ]; then
                found=true
            fi

        else
            session_file="$BASE_DIR/${session_name}.txt"
            if [ -f "$session_file" ]; then
                found=true
            fi
        fi
    fi

    if [ "$found" = false ]; then
        echo "Error: Session '$session_name' not found."
        echo "$(date): Error - Session file not found for deletion: $session_file" >> /tmp/tmux_resurrect_manager.log
        list_sessions
        return 1
    fi

    rm -f "$session_file" "${session_file}.meta" 2>/dev/null
    local delete_result=$?

    # Delete shell history for this session if history isolation is enabled
    if [ "$ISOLATE_SHELL_HISTORY" = "true" ] && [ -d "$HISTORY_DIR/$session_name" ]; then
        rm -rf "$HISTORY_DIR/$session_name" 2>/dev/null
        echo "$(date): Deleted shell history for session: $session_name" >> /tmp/tmux_resurrect_manager.log
    fi

    if [ $delete_result -eq 0 ]; then
        echo "Session deleted: $session_name"
        echo "$(date): Successfully deleted session: $session_name" >> /tmp/tmux_resurrect_manager.log
    else
        echo "Error: Failed to delete session: $session_name"
        echo "$(date): Error - Failed to delete session: $session_name (exit code: $delete_result)" >> /tmp/tmux_resurrect_manager.log
    fi

    return $delete_result
}

interactive_menu() {
    if [ -z "$TMUX" ]; then
        echo "Error: Not running inside a tmux session."
        return 1
    fi

    # Create a temporary directory for our files
    local tmp_dir=$(mktemp -d)
    local menu_file="$tmp_dir/menu.txt"
    local result_file="$tmp_dir/result.txt"
    local fzf_script="$tmp_dir/fzf_script.sh"
    local theme_file="$tmp_dir/theme.sh"

    # Get theme colors dynamically
    eval "$(get_nvchad_colors)"

    # Helper function to convert hex to ANSI RGB
    hex_to_ansi() {
        local hex="$1"
        if [ "$hex" = "reset" ]; then
            printf "\e[0m"
            return
        fi
        # Remove # if present
        hex=${hex#\#}
        # Extract R, G, B
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        printf "\e[38;2;%d;%d;%dm" "$r" "$g" "$b"
    }
    local reset_color=$(hex_to_ansi reset)

    # Debug the theme colors
    log_theme "Theme colors before writing to vars file: HEADER=$HEADER_COLOR, TEXT=$TEXT_COLOR, BG=$BG_COLOR"

    cat > "$theme_file.vars" << EOF
HEADER_COLOR="$HEADER_COLOR"
ACTION_COLOR="$ACTION_COLOR"
SESSION_COLOR="$SESSION_COLOR"
TEXT_COLOR="$TEXT_COLOR"
BG_COLOR="$BG_COLOR"
BG_SELECT_COLOR="$BG_SELECT_COLOR"
BORDER_COLOR="$BORDER_COLOR"
PROMPT_COLOR="$PROMPT_COLOR"
POINTER_COLOR="$POINTER_COLOR"
SPINNER_COLOR="$SPINNER_COLOR"
INFO_COLOR="$INFO_COLOR"
MARKER_COLOR="$MARKER_COLOR"
HL_COLOR="$HL_COLOR"
HL_SELECT_COLOR="$HL_SELECT_COLOR"
THEME_NAME="${theme_name:-$THEME_NAME}"
EOF

    # Debug the theme vars file
    log_theme "Theme vars file created with content:"
    cat "$theme_file.vars" | head -5 >> /tmp/tmux_resurrect_manager.log

    {
        # Define colors using the helper
        local header_fg=$(hex_to_ansi "$HEADER_COLOR")
        local action_fg=$(hex_to_ansi "$ACTION_COLOR")
        local session_fg=$(hex_to_ansi "$SESSION_COLOR")
        local text_fg=$(hex_to_ansi "$TEXT_COLOR")
        local border_fg=$(hex_to_ansi "$BORDER_COLOR")
        local separator="──────────────────────────────" # Simple separator line

        echo ""

        echo "${header_fg}=== SAVED SESSIONS ===${reset_color}"
        echo "${border_fg}${separator}${reset_color}" # Separator line
        local has_saved=false

        if [ -f "$SESSION_INDEX_FILE" ]; then
            if command -v rg >/dev/null 2>&1; then
                local saved_sessions=$(rg -v "^#" "$SESSION_INDEX_FILE" | rg -v "^default\|" | wc -l)
            else
                local saved_sessions=$(grep -v "^#" "$SESSION_INDEX_FILE" | grep -v "^default|" | wc -l)
            fi

            if [ "$saved_sessions" -gt 0 ]; then
                has_saved=true

                # Use ripgrep if available, otherwise fall back to grep
                if command -v rg >/dev/null 2>&1; then
                    rg -v "^#" "$SESSION_INDEX_FILE" | rg -v "^default\|" | while IFS="|" read -r name file timestamp; do
                        if [ -n "$name" ] && [ -n "$file" ] && [ "$name" != "default" ]; then
                            local formatted_time=$(echo "$timestamp" | sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\) \([0-9]\{2\}\):\([0-9]\{2\}\):\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
                            printf "%s%-15s%s %ssaved: %s%s\n" "$session_fg" "$name" "$reset_color" "$text_fg" "$formatted_time" "$reset_color"
                        fi
                    done
                else
                    grep -v "^#" "$SESSION_INDEX_FILE" | grep -v "^default|" | while IFS="|" read -r name file timestamp; do
                        if [ -n "$name" ] && [ -n "$file" ] && [ "$name" != "default" ]; then
                            local formatted_time=$(echo "$timestamp" | sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\) \([0-9]\{2\}\):\([0-9]\{2\}\):\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
                            printf "%s%-15s%s %ssaved: %s%s\n" "$session_fg" "$name" "$reset_color" "$text_fg" "$formatted_time" "$reset_color"
                        fi
                    done
                fi
            fi
        fi

        if [ "$has_saved" = false ]; then
            echo "${text_fg}No saved sessions found.${reset_color}"
        fi
        # Add blank line only if there were saved sessions
        if [ "$has_saved" = true ]; then
             echo "" # Blank line for separation
        fi

        # Default session
        local latest_file=$(find_latest_session)
        if [ -n "$latest_file" ]; then
            local timestamp=$(basename "$latest_file" | sed 's/tmux_resurrect_//' | sed 's/\.txt$//')
            local date_display=$(echo "$timestamp" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
            printf "%s%-15s%s %slatest: %s%s\n" "$session_fg" "default" "$reset_color" "$text_fg" "$date_display" "$reset_color"
        fi
    } > "$menu_file"

    # Create a standalone fzf script that will run in the tmux pane
    cat > "$fzf_script" << EOF
#!/bin/bash

# Source the theme vars file directly
if [ -f "$theme_file.vars" ]; then
    source "$theme_file.vars"
    echo "$(date): Sourced theme vars file: HEADER=$HEADER_COLOR, TEXT=$TEXT_COLOR, THEME=$THEME_NAME" >> /tmp/tmux_resurrect_manager.log
else
    echo "$(date): ERROR: Theme vars file not found!" >> /tmp/tmux_resurrect_manager.log
fi

# No pre-processing needed for the menu file

# Function to run fzf with the menu
run_fzf() {
    # Clear the screen first to avoid any artifacts
    clear

    # Set up colors and styling for fzf using dynamically loaded hex values
    export FZF_DEFAULT_OPTS="
      --ansi
      --height=100%
      --layout=reverse
      --border=rounded
      --prompt='Select session (s:save, d:delete, r:refresh) > '
      --pointer='▶'
      --marker='✓'
      --header='Tmux Resurrect Session Manager'
      --color=bg+:$BG_SELECT_COLOR,bg:$BG_COLOR,spinner:$SPINNER_COLOR,hl:$HL_COLOR,fg:$TEXT_COLOR,header:$HEADER_COLOR,info:$INFO_COLOR,pointer:$POINTER_COLOR,marker:$MARKER_COLOR,fg+:$TEXT_COLOR,prompt:$PROMPT_COLOR,hl+:$HL_SELECT_COLOR,border:$BORDER_COLOR
    "

    # Add theme name to the header if available
    if [ -n "\$THEME_NAME" ]; then
        export FZF_DEFAULT_OPTS="\$FZF_DEFAULT_OPTS --header='Tmux Resurrect Session Manager (Theme: \$THEME_NAME)'"
    fi

    # No preprocessing needed - we'll handle unselectable lines differently
    echo "$(date): Using direct menu display approach" >> /tmp/tmux_resurrect_manager.log

    # Debug message
    echo "$(date): Attempting to run fzf menu" >> /tmp/tmux_resurrect_manager.log

    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        echo "$(date): Error - fzf command not found" >> /tmp/tmux_resurrect_manager.log
        echo "Error: fzf command not found. Please install fzf."
        return 1
    fi

    # Use a simpler approach with fzf
    selection=\$(cat "$menu_file" | SHELL=/bin/bash fzf \
        --height=100% \
        --layout=reverse \
        --border=rounded \
        --ansi \
        --header="Enter: restore session | s: save new | d: delete selected | r: refresh" \
        --prompt="Select session > " \
        --expect="s,d,r" 2>/tmp/fzf_error.log || echo "FZF_ERROR")

    # Check for errors
    if [ "\$selection" = "FZF_ERROR" ]; then
        echo "$(date): Error running fzf. Check /tmp/fzf_error.log" >> /tmp/tmux_resurrect_manager.log
        if [ -f "/tmp/fzf_error.log" ]; then
            cat "/tmp/fzf_error.log" >> /tmp/tmux_resurrect_manager.log
        fi
        echo "Error running fzf menu. See /tmp/tmux_resurrect_manager.log for details."
        return 1
    fi

    # Process the selection
    # Log the selection for debugging
    echo "$(date): Selection: '\$selection'" >> /tmp/tmux_resurrect_manager.log

    # Check if selection is empty (user aborted)
    if [ -z "\$selection" ]; then
        # User aborted the menu
        echo "abort:" > "$result_file"
        echo "$(date): User aborted the menu" >> /tmp/tmux_resurrect_manager.log
        return 0
    fi

    # With --expect, fzf returns two lines: the key pressed and the selected item
    # Read both lines into variables
    local key=\$(echo "\$selection" | head -1)
    local item=\$(echo "\$selection" | tail -1)

    echo "$(date): Key: '\$key', Item: '\$item'" >> /tmp/tmux_resurrect_manager.log

    # Handle based on the key pressed
    if [ "\$key" = "s" ]; then
        # Save action - prompt for session name
        local session_name=\$(echo "" | fzf --print-query --prompt="Enter session name > " --header="Type a name for your session and press Enter")

        if [ -n "\$session_name" ]; then
            echo "save:\$session_name" > "$result_file"
            echo "$(date): Save session with name: \$session_name" >> /tmp/tmux_resurrect_manager.log
        else
            # If no name provided, refresh the menu
            echo "refresh:" > "$result_file"
            echo "$(date): No session name provided for save, refreshing menu" >> /tmp/tmux_resurrect_manager.log
        fi
    elif [ "\$key" = "d" ]; then
        # Delete action - use the selected item
        if [ -z "\$item" ] || [[ "\$item" == *"==="* ]] || [[ "\$item" == *"───"* ]]; then
            # If no valid item selected, refresh the menu
            echo "refresh:" > "$result_file"
            echo "$(date): No valid item selected for deletion, refreshing menu" >> /tmp/tmux_resurrect_manager.log
        else
            # Extract session name (first word before space or parenthesis)
            local session_name=\$(echo "\$item" | awk '{print \$1}')
            if [ -n "\$session_name" ]; then
                echo "delete:\$session_name" > "$result_file"
                echo "$(date): Selected to delete session: \$session_name" >> /tmp/tmux_resurrect_manager.log
            else
                # If we couldn't extract a session name, refresh the menu
                echo "refresh:" > "$result_file"
                echo "$(date): Could not extract session name for delete, refreshing menu" >> /tmp/tmux_resurrect_manager.log
            fi
        fi
    elif [ "\$key" = "r" ]; then
        # Refresh action
        echo "refresh:" > "$result_file"
        echo "$(date): Selected refresh action" >> /tmp/tmux_resurrect_manager.log
    else
        # Enter key or other key - restore the selected session
        if [ -z "\$item" ] || [[ "\$item" == *"==="* ]] || [[ "\$item" == *"───"* ]]; then
            # If it's a header or blank line, refresh the menu
            echo "refresh:" > "$result_file"
            echo "$(date): No valid item selected for restore, refreshing menu" >> /tmp/tmux_resurrect_manager.log
        elif [[ "\$item" == default* ]]; then
            echo "restore:default" > "$result_file"
            echo "$(date): Selected default session" >> /tmp/tmux_resurrect_manager.log
        else
            # Extract session name (first word before space or parenthesis)
            local session_name=\$(echo "\$item" | awk '{print \$1}')
            if [ -n "\$session_name" ]; then
                echo "restore:\$session_name" > "$result_file"
                echo "$(date): Selected session: \$session_name" >> /tmp/tmux_resurrect_manager.log
            else
                # If we couldn't extract a session name, refresh the menu
                echo "refresh:" > "$result_file"
                echo "$(date): Could not extract session name, refreshing menu" >> /tmp/tmux_resurrect_manager.log
            fi
        fi
    fi
}

# Run fzf in the current pane
run_fzf
EOF
    chmod +x "$fzf_script"

    export BASE_DIR="$BASE_DIR"
    export DEFAULT_DIR="$DEFAULT_DIR"
    export HEADER_COLOR="$HEADER_COLOR" ACTION_COLOR="$ACTION_COLOR" SESSION_COLOR="$SESSION_COLOR" TEXT_COLOR="$TEXT_COLOR"
    export BG_COLOR="$BG_COLOR" BG_SELECT_COLOR="$BG_SELECT_COLOR" BORDER_COLOR="$BORDER_COLOR" PROMPT_COLOR="$PROMPT_COLOR"
    export POINTER_COLOR="$POINTER_COLOR" SPINNER_COLOR="$SPINNER_COLOR" INFO_COLOR="$INFO_COLOR" MARKER_COLOR="$MARKER_COLOR"
    export HL_COLOR="$HL_COLOR" HL_SELECT_COLOR="$HL_SELECT_COLOR" THEME_NAME="${theme_name:-$THEME_NAME}"
    export result_file="$result_file"
    export menu_file="$menu_file"

    "$fzf_script"

    local selection=""
    if [ -f "$result_file" ]; then
        selection=$(cat "$result_file")
    fi

    if [[ "$selection" == abort:* ]]; then
        return 0
    elif [[ "$selection" == save:* ]]; then
        local session_name=$(echo "$selection" | cut -d':' -f2)
        if [ -n "$session_name" ]; then
            # Clear the screen and show a saving message
            clear
            echo "===== TMUX RESURRECT MANAGER ====="
            echo ""
            echo "Saving session as: $session_name"
            echo ""

            # Save the session
            save_session "$session_name" 2>&1

            echo ""
            echo "Press any key to continue or Esc to exit..."
            read -n 1 key
            if [[ "$key" == $'\e' ]]; then
                return 0
            else
                interactive_menu
            fi
        fi
    elif [[ "$selection" == restore:* ]]; then
        local session_name=$(echo "$selection" | cut -d':' -f2)
        if [ -n "$session_name" ]; then
            # Clear the screen and show a restoring message
            clear
            echo "===== TMUX RESURRECT MANAGER ====="
            echo ""
            echo "Restoring session: $session_name"
            echo ""

            # Restore the session
            restore_session "$session_name" 2>&1

            echo ""
            echo "Press any key to continue or Esc to exit..."
            read -n 1 key
            if [[ "$key" == $'\e' ]]; then
                return 0
            else
                interactive_menu
            fi
        fi
    elif [[ "$selection" == delete:* ]]; then
        local session_name=$(echo "$selection" | cut -d':' -f2)
        if [ -n "$session_name" ]; then
            # Clear the screen and show a confirmation message
            clear
            echo "===== TMUX RESURRECT MANAGER ====="
            echo ""
            echo "Delete session: $session_name"
            echo ""
            echo -n "Are you sure you want to delete this session? (y/n): "
            read -n 1 confirm
            echo ""
            echo ""

            if [[ "$confirm" == "y" ]]; then
                echo "Deleting session..."
                echo ""
                # Delete the session
                delete_session "$session_name" 2>&1
                echo ""
                echo "Session deleted successfully."
            else
                echo "Deletion cancelled."
            fi

            echo ""
            echo "Press any key to continue or Esc to exit..."
            read -n 1 key
            if [[ "$key" == $'\e' ]]; then
                return 0
            else
                interactive_menu
            fi
        fi
    elif [[ "$selection" == refresh:* ]]; then
        interactive_menu
    fi

    [ -d "$tmp_dir" ] && rm -rf "$tmp_dir" 2>/dev/null
}

main() {
    local command="$1"
    local session_name="$2"

    echo "$(date): main() called with command: $command, session_name: $session_name" >> /tmp/tmux_resurrect_manager.log

    case "$command" in
        save)
            save_session "$session_name"
            exit_code=$?
            ;;
        restore)
            restore_session "$session_name"
            exit_code=$?
            ;;
        list)
            list_sessions
            exit_code=$?
            ;;
        delete)
            delete_session "$session_name"
            exit_code=$?
            ;;
        menu|interactive)
            interactive_menu
            exit_code=$?
            ;;
        json)
            list_sessions "json"
            exit_code=$?
            ;;
        *)
            echo "Usage: $0 {save|restore|list|delete|menu|json} [session_name]"
            echo "  save [session_name]    - Save current tmux environment as session_name"
            echo "  restore [session_name] - Restore tmux environment from session_name"
            echo "  list                   - List available saved sessions"
            echo "  delete session_name    - Delete a saved session"
            echo "  menu                   - Show interactive menu (requires tmux)"
            echo "  json                   - Output session list in JSON format"
            echo ""
            echo "If session_name is not provided, 'default' will be used."
            echo "$(date): Error - Invalid command: $command" >> /tmp/tmux_resurrect_manager.log
            exit_code=1
            ;;
    esac

    echo "$(date): Exiting with code: $exit_code" >> /tmp/tmux_resurrect_manager.log
    exit $exit_code
}

main "$@"
