#!/bin/bash

function install_pixi() {
	if ! command -v pixi &>/dev/null; then
		curl -fsSL https://pixi.sh/install.sh | bash
		export PATH="$PATH:$HOME/.pixi/bin"
	else
		return 0
	fi
}

function install_cargo() {

	if ! command -v cargo &>/dev/null; then
		sudo pacman -S --needed base-devel rustup --noconfirm
		rustup default stable
		cargo install cargo-binstall
		cargo binstall cargo-cache cargo-update
	else
		return 0
	fi

}

function install_paru() {

	if ! command -v paru &>/dev/null; then
		# because paru is in the AUR we can't install it from pacman
		# but we want to be able to update itself so we'll
		# install one version manually, then install paru through that
		# and remove the version we just installed
		if [ ! -d paru-bin ]; then
			git clone https://aur.archlinux.org/paru-bin.git
		fi
		makepkg -si --noconfirm --dir paru-bin
		paru -S bat --noconfirm
		rm -rf paru-bin
	fi

}

function install_flatpak() {
	if ! command -v flatpak &>/dev/null; then
		sudo pacman -S --needed flatpak --noconfirm
	fi
}

# Function to check if a tool is installed
function is_installed() {
	local manager=$1
	local tool=$2

	case "$manager" in
	cargo)
		cargo install --list | grep -q "$tool"
		;;
	paru)
		paru -Q "$tool"
		;;
	flatpak)
		flatpak list | grep -q "$tool"
		;;
	pixi)
		pixi global list | grep -q "$tool"
		;;
	*)
		echo "Unknown package manager: $manager"
		return 1
		;;
	esac
}

# General installation function that can handle different package managers
function install_tools() {
	local manager=$1
	shift # Remove the manager argument from the list
	local tools=("$@")

	if [ "${#tools[@]}" -eq 0 ]; then
		return 1
	fi

	# Loop through each tool
	for t in "${tools[@]}"; do
		# Check if the tool is already installed, based on the manager
		if ! is_installed "$manager" "$t"; then
			echo "$t already installed, skipping..."
		else
			# Perform the installation
			case "$manager" in
			cargo)
				cargo install "$t"
				;;
			flatpak)
				flatpak install "$t" -y
				;;
			pixi)
				pixi global install "$t"
				;;
			*)
				echo "Unknown package manager: $manager"
				return 1
				;;
			esac
		fi
	done
}

function install_helix_fork() {

	if [ -f "$HOME/.cargo/bin/hx" ]; then
		return 0
	fi

	mkdir -p ~/projects/rust

	pushd ~/projects/rust || exit 1
	git clone git@github.com:savente93/helix.git
	pushd helix || exit 1
	git checkout bin
	cargo install --path helix-term --locked

	# just in case
	rm -rf ~/.config/helix/runtime
	ln -s "$PWD"/runtime ~/.config/helix/ -f

	# download theme
	curl -Ssfo ~/.config/helix/themes/onedark.toml https://raw.githubusercontent.com/helix-editor/helix/master/runtime/themes/onedark.toml

	~/.cargo/bin/hx -g fetch
	~/.cargo/bin/hx -g build

	popd || exit 1
	popd || exit 1

}

function setup_internet() {

	nmcli d wifi connect -a "$(nmcli -f SSID d wifi list | sort | uniq | grep -v SSID | grep -o '[^[:space:]].*[^[:space:]]' | fzf --header "Please select a wifi network")"
	install_tool paru ufw ssh curl chrony

	timedatectl set-timezone Europe/Amsterdam

	sudo systemctl enable --now NetworkManager.service
	sudo systemctl enable --now chronyd.service

}

function setup_audio() {
	install_tools paru pipewire pipewire-pulse qpwgraph wireplumber
	systemctl enable --now --user pipewire-pulse
	sudo systemctl enable --now bluetooth.service
	systemctl --user --now enable wireplumber
	install_tools flatpak spotify
}

function setup_power_management() {

	install_tools paru acpi
	# make sure laptop hybernates when battery is too low
	# ls | grep is fine in this case and the alternative is needlessly complicated
	# shellcheck disable=SC2010
	if ls /sys/class/power_supply | grep -q BAT; then
		echo 'SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-7]", RUN+="/usr/bin/systemctl hibernate"' | sudo tee /etc/udev/rules.d/99-lowbat.rules
	fi
}

function setup_wezterm() {

	curl -Ssfo ~/.wezterm.sh https://raw.githubusercontent.com/wez/wezterm/refs/heads/main/assets/shell-integration/wezterm.sh
	install_tools paru wezterm stylua lua-language-server

}

function setup_terminal() {

	install_helix_fork
	setup_wezterm

	install_tools pixi pre-commit
	install_tools paru dust eza fd lazygit ripgrep starship topgrade-bin zoxide tz yazi

	# don't want fish to start when we install it so it get's handled seperately
	sudo pacman -S --needed --noconfirm fish

	echo "creating symlinks"
	ln -s ~/Documents/dotfiles/.wezterm.lua ~/.wezterm.lua -f
	ln -s ~/Documents/dotfiles/.bashrc ~/.bashrc -f
	ln -s ~/Documents/dotfiles/.gitignore ~/.gitignore -f
	ln -s ~/Documents/dotfiles/.gitconfig ~/.gitconfig -f
	ln -s ~/Documents/dotfiles/starship.toml ~/.config/starship.toml -f
	ln -s ~/Documents/dotfiles/topgrade.toml ~/.config/topgrade.toml -f
	ln -s ~/Documents/dotfiles/fish ~/.config/ -f
	ln -s ~/Documents/dotfiles/lazygit ~/.config/ -f
	ln -s ~/Documents/dotfiles/paru/ ~/.config/ -f
	ln -s ~/Documents/dotfiles/wireplumber/ ~/.config/ -f
	sudo rm /etc/pacman.conf
	sudo ln -s ~/Documents/dotfiles/pacman.conf /etc/pacman.conf -f

}

function setup_writing_tools() {

	install_tools paru bibtex-tidy d2 evince jinja-lsp marksman texlab typos typst typst-lsp-bin zola

	#set evince as defatul pdf application
	xdg-mime default org.gnome.Evince.desktop application/pdf
	gio mime application/pdf org.gnome.Evince.desktop

	install_tools cargo jinja-lsp
	install_tools pixi djlint

}

function setup_python_tools() {
	install_tools paru pyright ruff-lsp

}

function setup_rust_tools() {
	install_tools paru rustup rust-analyzer taplo-cli

}

function setup_bash_tools() {
	install_tools paru bash-language-server shellcheck shfmt yaml-language-server
}

function setup_infra_tools() {
	install_tools pixi awscli
	install_tools paru terraform-ls
}

function setup_espanso() {
	install_tools paru espanso-wayland-git
	espanso service register

	mkdir -p ~/.config/espanso
	rm -rf ~/.config/espanso/*
	ln -s ~/Documents/dotfiles/espanso/config ~/.config/espanso/ -f
	ln -s ~/Documents/dotfiles/espanso/match ~/.config/espanso/ -f
}

function setup_fonts() {
	install_tools paru noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-firacode-nerd ttf-font-awesome
	mkdir -p ~/.local/share/fonts{Clicker_Script,EB_Garmond}
	curl -Ls -o ~/.local/share/fonts/Clicker_Script/ClickerScript-Regular.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/clickerscript/ClickerScript-Regular.ttf
	curl -Ls -o "$HOME/.local/share/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf" https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf
	curl -Ls -o "$HOME/.local/share/fonts/EB_Garamond/EBGaramond-Italic-VariableFont_wght.ttf" https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/EBGaramond-Italic%5Bwght%5D.ttf
}

function setup_de() {
	paru -S brightnessctl cronie gammastep grim lxappearance sddm sddm-catppuccin-git slurp swappy swaybg swayidle swaylock waybar webp-pixbuf-loader xdg-desktop-portal xdg-desktop-portal thunar xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal-wlr --noconfirm
	mkdir -p ~/{.local/bin,.config}/rofi
	mkdir -p ~/Wallpapers
	curl https://raw.githubusercontent.com/gh0stzk/dotfiles/master/config/bspwm/rices/andrea/walls/wall-01.webp -o ~/Wallpapers/wall.webp
	curl https://wallpapercave.com/wp/wp2639448.png -o ~/Wallpapers/locked.png

}

function setup_games() {
	flatpak install -y com.valvesoftware.Steam
}

function setup_dotfiles() {
	install_tools paru stow
	if [ ! -d ~/dotfiles ]; then
		git clone https://github.com/savente93/dotfiles.git ~/dotfiles
		pushd ~/dotfiles || exit 1
		git remote set-url origin git@github.com:savente93/dotfiles.git
		stow .
		popd || exit 1
	fi
}

function setup_1password() {
	echo "setting up secruity"

	if ! command -v 1password; then
		echo "installing 1password"

		curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
		install_tools paru 1password 1password-cli rofi-1pass aws-credential-1password

		read -r -p "1Password has been installed. Please unlock it and enable the CLI. Press Enter to continue..." -s -n1 </dev/tty
		op vault list || exit 1
	fi

	mkdir -p ~/.config/autostart
	if [ ! -f ~/.config/autostart/1password.desktop ]; then
		echo "creating 1password autostart"
		mkdir -p ~/.config/autostart
		# autostart 1password at login
		echo -e "[Desktop Entry]\nType=Application\nExec=/usr/bin/1password --silent\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_GB]=1Password\nName=1Password\nComment[en_GB]=\nComment=" >~/.config/autostart/1password.desktop
	fi
}

function setup_ssh() {

	paru -S wikiman base-devel --noconfirm

	install_tools paru keychain openssh openssl
	sudo systemctl enable --now ufw.service
	sudo systemctl enable --now sshd.service
	# ssh
	echo "setting up ssh identities"
	mkdir -p ~/.ssh
	chmod -R 700 ~/.ssh

	# add github to known hosts
	ssh-keyscan github.com >githubKey
	ssh-keygen -lf githubKey >>~/.ssh/known_hosts
	rm githubKey

	ssh-keyscan git.sam-vente.com >personal_git_key
	ssh-keygen -lf personal_git_key >>~/.ssh/known_hosts
	rm personal_git_key

	# get sshkeys from password manager
	key_type=$(op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "key type")

	if [ -z "$key_type" ]; then
		echo "Could not determine key type..."
		return 1
	fi

	op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "public key" >"$HOME/.ssh/id_$key_type.pub"
	chmod 644 "$HOME/.ssh/id_$key_type.pub"

	# wooooooow libcrypto is a fussy bitch
	op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "private key" --reveal | tr -d '"' | tr -d "\r" | sed -r '/^\s*$/d' >"$HOME/.ssh/id_$key_type"
	chmod 600 "$HOME/.ssh/id_$key_type"

	echo "Host *" >~/.ssh/config
	echo "IdentityFile ~/.ssh/id_$key_type" >>~/.ssh/config

	# ssh connections only allowed through non root key based auth
	sudo sed -i -E "s/[#]?PasswordAuthentication (yes|no)/PasswordAuthentication no/;s/#?PubkeyAuthentication (yes|no)/PubkeyAuthentication yes/;s/#?PermitRootLogin (yes|no)/PermitRootLogin no/;s/#?AllowUsers .*/AllowUsers $USER/" /etc/ssh/sshd_config

	# allow ssh connections
	sudo ufw enable
	sudo ufw allow ssh

	# git by using the signing key each machine can have it's own key but still have a common gitconfig
	echo "[user]" >~/.gitconfig.signingkey
	echo -e "\tsigningkey = $(op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "public key")" >>~/.gitconfig.signingkey
}

function setup_docker() {
	# runtimes/compilers
	install_paru docker dockerfile-language-server docker-compose
	sudo usermod -aG docker sam
	if [ -z "$(getent group docker)" ]; then
		newgrp docker
	fi

	sudo systemctl enable --now docker.service

}

function setup_aws() {
	# aws cli
	mkdir -p ~/.aws
	echo -e "[default]\n\t" >~/.aws/credentials
	echo "aws_access_key_id = $(op item get 'AWS [Personal]' --fields username)" >>~/.aws/credentials
	echo "aws_secret_access_key= $(op item get 'AWS [Personal]' --fields credential)" >>~/.aws/credentials

}

function disable_root_login() {

	sudo sed -i -E 's/root:x:0:0:root:\/root:\/bin\/bash/root:x:0:0:root:\/root:\/usr\/sbin\/nologin/' /etc/passwd

}

function install_package_managers() {
	install_cargo
	install_paru
	install_pixi
	install_flatpak
}

function setup_common() {
	disable_root_login
	setup_internet
	install_package_managers
	setup_dotfiles
	setup_terminal
	setup_1password
	setup_ssh
	setup_espanso
	setup_de
	setup_fonts
	setup_audio

}

function setup_minimal() {
	setup_common
	setup_writing_tools
}

function setup_dev() {
	setup_python_tools
	setup_rust_tools
	setup_infra_tools
	setup_bash_tools
	setup_1password
	setup_docker
	setup_aws
}

function setup_all() {
	setup_common
	setup_writing_tools
	setup_dev
	setup_games
}

#get sudo rights for when we need it
sudo -v

group=$1
case "$group" in
all)
	setup_all
	;;
minimal)
	setup_minimal
	;;
#for if we want to source the functions
source)
	setup_all
	;;
*)
	echo "Unknown group: $group"
	return 1
	;;
esac
