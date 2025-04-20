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

```bash
# Backup your existing config if needed
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repository
git clone https://github.com/sevilzww/nvim-config.git ~/.config/nvim

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

- Automatic swap file cleanup when killing tmux windows with `prefix &`
- Seamless navigation between Neovim splits and tmux panes
- Terminal integration

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
