#!/bin/bash

set -e

# --------- CONFIGURATION ---------
GITHUB_REPO_URL="https://github.com/ZachP30/Kali-Tools.git"
TEMP_DIR="/tmp/kali-setup"
FISH_CONFIG_DIR="$HOME/.config/fish"
POSH_THEMES_DIR="$HOME/.poshthemes"
FISH_BIN="/usr/bin/fish"
COLORSCHEME_FILE="tokyo.colorscheme"
QTERMWIDGET_COLOR_DIR="/usr/share/qtermwidget6/color-schemes"
FONT_DIR="$HOME/.local/share/fonts"
# ---------------------------------

echo "[*] Updating package list..."
sudo apt update

echo "[*] Installing Fish Shell, Git, Curl if not installed..."
for pkg in fish git curl unzip; do
    if ! dpkg -s $pkg >/dev/null 2>&1; then
        echo "  - Installing $pkg..."
        sudo apt install -y $pkg
    else
        echo "  - $pkg already installed, skipping."
    fi
done

echo "[*] Installing Oh My Posh..."

if command -v oh-my-posh >/dev/null 2>&1; then
    echo "  - oh-my-posh already installed at $(command -v oh-my-posh), skipping."
else
    ARCH=$(uname -m)
    echo "  - Detected architecture: $ARCH"

    if [[ "$ARCH" == "x86_64" ]]; then
        OMP_BINARY="posh-linux-amd64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        OMP_BINARY="posh-linux-arm64"
    elif [[ "$ARCH" == "armv7l" ]]; then
        OMP_BINARY="posh-linux-arm"
    else
        echo "  - Unsupported architecture: $ARCH"
        exit 1
    fi

    echo "  - Downloading oh-my-posh binary for $ARCH..."
    curl -Lo oh-my-posh "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/$OMP_BINARY"
    chmod +x oh-my-posh
    sudo mv oh-my-posh /usr/local/bin/oh-my-posh
    echo "  - oh-my-posh installed to /usr/local/bin/oh-my-posh"
fi

echo "[*] Cloning your config repo..."
if [ -d "$TEMP_DIR" ]; then
    echo "  - $TEMP_DIR exists, removing..."
    rm -rf "$TEMP_DIR"
fi
git clone "$GITHUB_REPO_URL" "$TEMP_DIR"

echo "[*] Setting up Fish config..."
if [ -d "$FISH_CONFIG_DIR" ]; then
    echo "  - $FISH_CONFIG_DIR exists, backing up..."
    mv "$FISH_CONFIG_DIR" "$FISH_CONFIG_DIR.bak.$(date +%s)"
fi
mkdir -p "$(dirname "$FISH_CONFIG_DIR")"
cp -r "$TEMP_DIR/fish" "$FISH_CONFIG_DIR"

# Ensure /usr/local/bin is in Fish PATH
FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"
if ! grep -q "/usr/local/bin" "$FISH_CONFIG_FILE"; then
    echo "set -gx PATH /usr/local/bin \$PATH" | cat - "$FISH_CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$FISH_CONFIG_FILE"
    echo "  - Added /usr/local/bin to PATH in config.fish"
else
    echo "  - /usr/local/bin already in config.fish PATH, skipping."
fi

echo "[*] Setting up Oh My Posh themes..."
mkdir -p "$POSH_THEMES_DIR"
if [ "$(ls -A $POSH_THEMES_DIR 2>/dev/null)" ]; then
    echo "  - $POSH_THEMES_DIR is not empty, backing up..."
    mv "$POSH_THEMES_DIR" "${POSH_THEMES_DIR}.bak.$(date +%s)"
    mkdir -p "$POSH_THEMES_DIR"
fi
cp -r "$TEMP_DIR/poshthemes/"* "$POSH_THEMES_DIR"
chmod u+rw "$POSH_THEMES_DIR"/*

echo "[*] Ensuring Fish is in /etc/shells..."
if ! grep -qx "$FISH_BIN" /etc/shells; then
    echo "$FISH_BIN" | sudo tee -a /etc/shells > /dev/null
    echo "  - Added $FISH_BIN to /etc/shells"
else
    echo "  - $FISH_BIN already in /etc/shells"
fi

echo "[*] Changing your default shell to Fish..."
current_shell=$(getent passwd $USER | cut -d: -f7)
if [ "$current_shell" != "$FISH_BIN" ]; then
    echo "🔐 You may be prompted for your password to authorize the shell change."
    chsh -s "$FISH_BIN" "$USER"
    echo "  - Default shell changed to Fish"
else
    echo "  - Fish is already your default shell, skipping."
fi

echo "[*] Installing 'tokyo' color scheme for QTermWidget terminals..."
if [ -f "$TEMP_DIR/$COLORSCHEME_FILE" ]; then
    if [ ! -f "$QTERMWIDGET_COLOR_DIR/$COLORSCHEME_FILE" ]; then
        sudo cp "$TEMP_DIR/$COLORSCHEME_FILE" "$QTERMWIDGET_COLOR_DIR/"
        echo "  - Tokyo Night color scheme installed to $QTERMWIDGET_COLOR_DIR"
    else
        echo "  - Tokyo Night color scheme already exists, skipping."
    fi
else
    echo "  - tokyo.colorscheme file not found in repo!"
fi

echo "[*] Installing FiraCode Nerd Font..."

mkdir -p "$FONT_DIR"
FIRA_FONT_ZIP="$TEMP_DIR/FiraCode.zip"
FIRA_GH_RELEASES_API="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"

FIRA_ZIP_URL=$(curl -s $FIRA_GH_RELEASES_API | grep "browser_download_url" | grep "FiraCode.zip" | cut -d '"' -f 4)

if [ -z "$FIRA_ZIP_URL" ]; then
    echo "  - ERROR: Could not find FiraCode Nerd Font download URL."
else
    echo "  - Downloading FiraCode Nerd Font from $FIRA_ZIP_URL"
    curl -L -o "$FIRA_FONT_ZIP" "$FIRA_ZIP_URL"
    echo "  - Extracting fonts..."
    unzip -o "$FIRA_FONT_ZIP" '*.ttf' -d "$FONT_DIR"
    rm "$FIRA_FONT_ZIP"
    echo "  - Refreshing font cache..."
    fc-cache -fv > /dev/null
    echo "  - FiraCode Nerd Font installed."
fi

# Fallback: Ensure terminal starts fish shell if it doesn't respect login shell
#if ! grep -q "exec $FISH_BIN" "$HOME/.bashrc"; then
#    echo "exec $FISH_BIN" >> "$HOME/.bashrc"
#    echo "  - Added 'exec fish' to ~/.bashrc to start fish automatically."
#else
#    echo "  - 'exec fish' already in ~/.bashrc, skipping."
#fi

echo "[*] Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "[✓] Setup complete!"
echo "➡️ Please log out and log back in or restart your terminal."
echo "➡️ Set your terminal font to 'FiraCode Nerd Font' (or another Nerd Font) for icons to display correctly."
echo "➡️ Your default shell is now Fish, with Oh My Posh themes and your color scheme installed. NOTE: BE SURE TO CHANGE TERMINAL PREFERENCES TO Fira Code Nerd Font INSIDE YOUR TERMINAL SETTINGS!"
