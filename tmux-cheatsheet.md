## Basic Tmux Commands

### Session Management
- `tmux new-session -s <name>` - Create a new session with name
- `tmux attach-session -t <name>` - Attach to an existing session
- `tmux ls` - List all sessions
- `tmux kill-session -t <name>` - Kill a session
---

### Prefix Key
- The prefix key is set to `Ctrl+Space` (instead of the default `Ctrl+b`)
- Press the prefix key before any of the following commands
---

### Window Management
- `<prefix> c` - Create a new window
- `<prefix> ,` - Rename current window
- `<prefix> n` - Move to next window
- `<prefix> p` - Move to previous window
- `<prefix> w` - List all windows
- `<prefix> &` - Kill current window
- `<prefix> 0-9` - Switch to window number 0-9
---

### Pane Management
- `<prefix> |` - Split pane horizontally
- `<prefix> -` - Split pane vertically
- `<prefix> h/j/k/l` - Navigate between panes (Vim-style)
- `<prefix> q` - Show pane numbers
- `<prefix> x` - Kill current pane
- `<prefix> z` - Toggle pane zoom (maximize/restore)
- `<prefix> {` - Move current pane left
- `<prefix> }` - Move current pane right
- `<prefix> <arrow keys>` - Resize pane
---

### Copy Mode
- `<prefix> [` - Enter copy mode
- `q` - Exit copy mode
- `v` - Start selection (in vi mode)
- `y` - Copy selection (in vi mode)
- `<prefix> ]` - Paste copied text
---
<br/><br/>

## Vim-Tmux Integration

### Navigation Between Vim and Tmux
- `Ctrl+h` - Move left (works in both Vim and Tmux)
- `Ctrl+j` - Move down (works in both Vim and Tmux)
- `Ctrl+k` - Move up (works in both Vim and Tmux)
- `Ctrl+l` - Move right (works in both Vim and Tmux)
---

### Fast Pane Switching
- `Alt+h` - Move to left pane
- `Alt+j` - Move to down pane
- `Alt+k` - Move to up pane
- `Alt+l` - Move to right pane
---

### Vimux Commands
- `<leader>tr` - Run a command in tmux pane
- `<leader>tl` - Run last command
- `<leader>to` - Open runner pane
- `<leader>tc` - Close runner pane
- `<leader>ti` - Inspect runner pane
- `<leader>tx` - Interrupt runner
- `<leader>tz` - Zoom runner pane
---
<br/><br/>

## Custom Commands

### Launch Neovim with Terminal in Tmux
- `<leader>h` - Launch a new Neovim instance with terminal in tmux
- `:NewNvimWithTerminal` - Same as above, but as a command
---

### Tmux Configuration
- `<prefix> r` - Reload tmux configuration
---

## Tips for Multiple Neovim Instances

1. **Use Tmux Windows for Different Projects**:
   - Each window can be a separate project
   - Use `<prefix> w` to list and select windows

2. **Use Tmux Panes for Related Files**:
   - Split a window into panes for related files
   - Use `Ctrl+h/j/k/l` to navigate between panes

3. **Use Tmux Sessions for Different Contexts**:
   - Create different sessions for different contexts
   - Use `tmux ls` and `tmux attach-session -t <name>` to switch between sessions

4. **Use Tmux Copy Mode for Scrollback**:
   - Enter copy mode with `<prefix> [`
   - Use vi-like navigation (hjkl, Ctrl+u, Ctrl+d, etc.)
   - Search with `/`

5. **Use Tmux Status Bar for Information**:
   - The status bar shows session name, windows, and system information
<br/><br/>
---
