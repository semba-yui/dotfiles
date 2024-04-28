#!/usr/bin/env zsh

set -eu

link_to_homedir() {
    command echo "backup old dotfiles..."
    if [ ! -d "./dotbackup" ];then
        command echo "./dotbackup not found. Auto Make it"
        command mkdir "./dotbackup"
    fi

    # variables
    local current_dir
    current_dir="$(cd "$(dirname "$0")" && pwd)"
    local target_file

    # Link starship
    target_file="${HOME}/.config/starship.toml"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/starship.toml"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/./starship/starship.toml" "${HOME}/.config"

    # Link sheldon
    target_file="${HOME}/.config/sheldon/plugins.toml"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/sheldon.toml"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/sheldon/plugins.toml" "${HOME}/.config/sheldon"

    # Link mise
    target_file="${HOME}/.config/mise/config.toml"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/config.toml"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/mise/config.toml" "${HOME}/.config/mise"

    # Link Karabiner-Elements
    target_file="${HOME}/.config/karabiner/karabiner.json"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/karabiner.json"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/karabiner/karabiner.json" "${HOME}/.config/karabiner"

    # Link fzf
    target_file="${HOME}/.fzf.zsh"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/.fzf.zsh"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/fzf/.fzf.zsh" "${HOME}"

    # Link Zsh
    # zprofile
    target_file="${HOME}/.zprofile"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/.zprofile"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/zsh/.zprofile" "${HOME}"
    # zshrc
    target_file="${HOME}/.zshrc"
    if [ -e "${target_file}" ]; then
        command echo "Backup ${target_file}"
        command mv "${target_file}" "./dotbackup/.zshrc"
    fi
    command echo "Link ${target_file}"
    command ln -svf "${current_dir}/zsh/.zshrc" "${HOME}"
}

# Install Homebrew
if type brew > /dev/null 2>&1; then
    command echo "Homebrew is already installed."
else
    command echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ "$(uname -m)" = "arm64" ] ; then
        (echo; echo "eval $(/opt/homebrew/bin/brew shellenv)") >> /Users/"${USER}"/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    command echo "Homebrew has been installed successfully."
fi

# Install Command Line Tools
if xcode-select --print-path &> /dev/null; then
    command echo "Command line tools are already installed."
else
    command echo "Command line tools not found. Installing..."
    command xcode-select --install
    command echo "Command line tools have been installed successfully."
fi

# Install Rosetta 2
if [ "$(uname -m)" = "x86_64" ] ; then
    command echo "Rosetta 2 is not needed on Intel Macs."
else
    command echo "Rosetta 2 is needed on Apple Silicon Macs."
    if softwareupdate --install-rosetta --agree-to-license; then
        command echo "Rosetta 2 has been installed successfully."
    else
        command echo "Error: Failed to install Rosetta 2."
        exit 1
    fi
fi

# Install Homebrew packages
brew bundle --file=homebrew/Brewfile

link_to_homedir

exec "${SHELL}" -l
