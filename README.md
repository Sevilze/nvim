# Sevilz' Neovim Config

## Features
- NvChad-based configuration
- Harpoon2 for quick file navigation and bookmarking
- Tmux integration
- LSP support
- Telescope fuzzy finder

## Installation

### Step 1: Install Neovim

#### On Ubuntu/Debian
```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
```

#### On Arch Linux
```bash
sudo pacman -S neovim
```

#### On macOS
```bash
brew install neovim
```

#### From Source (for latest version)
```bash
git clone https://github.com/neovim/neovim
cd neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
```

### Step 2: Install This Configuration

#### Option 1: Using the Installation Script (Recommended)

```bash
# Clone this repository
git clone https://github.com/Sevilze/nvim.git ~/.config/nvim

# Run the installation script
cd ~/.config/nvim
./install.sh
```

The installation script will:
1. Set executable permissions for all scripts
2. Create necessary symlinks
3. Back up any existing configurations
4. Set up tmux integration if tmux is installed

#### Option 2: Manual Installation

```bash
# Backup your existing config if needed
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repository
git clone https://github.com/Sevilze/nvim.git ~/.config/nvim

# Make scripts executable
chmod +x ~/.config/nvim/scripts/*.sh

# Start Neovim
nvim
```

On first launch, the configuration will automatically:
1. Install Lazy.nvim (package manager)
2. Install NvChad and all required plugins
3. Set up the configuration

## Key Mappings

### General
- `<Space>` - Leader key
- `<Esc>` - Clear search highlights
- `<C-s>` - Save file
- `<C-c>` - Copy whole file
- `<C-z>` - Undo (works in insert mode too)
- `<C-S-z>` - Redo (works in insert mode too)

### Navigation
- `<leader>ff` - Find files
- `<leader>fa` - Find all files (including hidden)
- `<leader>fw` - Find word
- `<C-n>` - Toggle NvimTree file explorer

### Harpoon
- `<leader>md` - Add file to Harpoon
- `<leader>mf` - Open Harpoon menu
- `<leader>m[1-9]` - Jump to Harpoon mark 1-9
- `<leader><leader>[10-30]` - Jump to Harpoon mark 10-30
- `<leader>mz` - Navigate to previous Harpoon mark
- `<leader>mx` - Navigate to next Harpoon mark
- `<leader>ms` - Save Harpoon state to file
- `<leader>ml` - Reload Harpoon state from file
- `<leader>mc` - Clear Harpoon list

### Terminal
- `<leader>h` - Open terminal in current directory
- `<leader>ht` - Open horizontal terminal
- `<leader>v` - Open vertical terminal
- `<C-x>` - Exit terminal mode

### Buffers
- `<leader>b` - New buffer
- `<tab>` - Next buffer
- `<S-tab>` - Previous buffer
- `<leader>x` - Close buffer

### Utilities
- `<leader>cs` - Clean swap files
- `<leader>n` - Toggle line numbers
- `<leader>rn` - Toggle relative line numbers
- `<leader>hn` - Toggle hybrid line numbers

## Customization

To customize this configuration:

1. Edit files in `~/.config/nvim/lua/sevilzww/`:
   - `core/options.lua` - General Neovim options
   - `core/mappings.lua` - Key mappings
   - `plugins/*.lua` - Plugin configurations
   - `chadrc.lua` - NvChad specific settings

2. Add new plugins in `~/.config/nvim/lua/sevilzww/plugins/`

## Tmux Integration

This configuration works seamlessly with tmux. Key features:

- Automatic Harpoon state saving when killing tmux windows with `prefix &` or panes with `prefix x`
- Seamless navigation between Neovim splits and tmux panes
- Terminal integration

### Tmux Key Bindings

- `prefix Q` - Save Harpoon state and kill window
- `prefix x` - Save Harpoon state and kill pane
- `prefix H` - Manually save Harpoon state
- `prefix R` - Reload Harpoon state
- `prefix S` - Save tmux session with tmux-resurrect (prompts for name)
- `prefix L` - Restore tmux session with tmux-resurrect (prompts for name)
- `prefix M-s` - Display list of sessions in a popup window
- `prefix M-f` - Save list of sessions to /tmp/tmux_sessions.txt
- `prefix M-d` - Delete a saved tmux session (prompts for name)

### Tmux Resurrect (Multi-Session Support)

This configuration includes tmux-resurrect for persisting tmux sessions across system restarts:

- Multiple named sessions can be saved and restored independently
- Sessions are saved to `~/.tmux/resurrect/sessions/`
- Neovim sessions are preserved using the session strategy
- Pane contents are captured and restored
- Use `prefix S` to save a named session and `prefix L` to restore a specific session
- Use `prefix M-s` to display the list of sessions in a popup window and `prefix M-f` to save them to a file
- Use `prefix M-d` to delete sessions
- Debug logs are saved to `/tmp/tmux_resurrect_manager.log` if you encounter any issues

## Troubleshooting

### Swap File Errors

If you encounter swap file errors with Harpoon:

1. Use `<leader>cs` to clean swap files
2. Or restart Neovim

### Plugin Issues

If you encounter plugin issues:

```bash
# Remove the plugin cache and reinstall
rm -rf ~/.local/share/nvim
nvim
```

## Credits

- [NvChad](https://github.com/NvChad/NvChad) - Base configuration
- [ThePrimeagen/harpoon](https://github.com/ThePrimeagen/harpoon) - Quick file navigation
- [Lazyvim starter](https://github.com/LazyVim/starter) - Inspiration for the starter template
