#!/bin/bash

function install_pixi() {
	if ! command -v pixi &>/dev/null; then
		curl -fsSL https://pixi.sh/install.sh | bash
		if [[ ":$PATH:" != *":$HOME/.pixi/bin:"* ]]; then
			export PATH="$PATH:$HOME/.pixi/bin"
		fi
	fi
}

function install_cargo() {

	if ! command -v cargo &>/dev/null; then
		sudo pacman -S --needed base-devel rustup --noconfirm
		rustup default stable
		cargo install cargo-binstall
		cargo binstall cargo-cache cargo-update
	fi

}

function install_paru() {

	if ! command -v paru &>/dev/null; then
		# because paru is in the AUR we can't install it from pacman
		# but we want to be able to update itself so we'll
		# install one version manually, then install paru through that
		# and remove the version we just installed
		if [ ! -d paru ]; then
			git clone https://aur.archlinux.org/paru.git
		fi
		makepkg -si --noconfirm --dir paru
		paru -S bat --noconfirm
		rm -rf paru
		sudo pacman -Syyu
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
		cargo install --list | grep -q "\b$tool\b"
		;;
	paru)
		paru -Q "$tool" &>/dev/null
		;;
	flatpak)
		flatpak list | grep -q "\b$tool\b"
		;;
	pixi)
		pixi global list | grep -q "\b$tool\b"
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
		exit 1
	fi

	# Loop through each tool
	for t in "${tools[@]}"; do
		# Check if the tool is already installed, based on the manager
		if ! is_installed "$manager" "$t"; then
			# Perform the installation
			case "$manager" in
			paru)
				paru -S "$t" --noconfirm
				;;
			cargo)
				cargo binstall "$t" -y
				;;
			flatpak)
				flatpak install "$t" -y
				;;
			pixi)
				pixi global install "$t"
				;;
			*)
				echo "Unknown package manager: $manager"
				exit 1
				;;
			esac
		fi
	done
}

function setup_internet() {

	if ! nmcli d wifi list | grep -q -F '*'; then
		nmcli d wifi connect -a "$(nmcli -f SSID d wifi list | sort | uniq | grep -v SSID | grep -o '[^[:space:]].*[^[:space:]]' | fzf --header "Please select a wifi network")"
	fi

}

function setup_time_zone() {
	install_tools paru ufw curl chrony

	timedatectl set-timezone Europe/Amsterdam

	sudo systemctl enable --now NetworkManager.service
	sudo systemctl enable --now chronyd.service

}

function setup_audio() {
	install_tools paru pipewire pipewire-pulse qpwgraph wireplumber bluez
	systemctl enable --now --user pipewire-pulse
	sudo systemctl enable --now bluetooth.service
	systemctl --user --now enable wireplumber
	install_tools flatpak spotify
}

function setup_image_processing() {
	install_tools flatpak org.inkscape.Inkscape

}

function setup_power_management() {

	# check if system has a battery
	if upower -e | grep -q 'BAT'; then
		install_tools paru acpi

		# make sure laptop hybernates when battery is too low
		echo 'SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-7]", RUN+="/usr/bin/systemctl hibernate"' | sudo tee /etc/udev/rules.d/99-lowbat.rules

		# shellcheck disable=SC2016
		(
			crontab -l
			echo '* * * * * "/bin/bash" "/home/sam/.local/bin/notify_battery.sh"'
		) 2>&1 | grep -v "no crontab" | sort | uniq | crontab -
	fi
}

function setup_wezterm() {

	if [ ! -f ~/.wezterm.sh ]; then
		curl -Ssfo ~/.wezterm.sh https://raw.githubusercontent.com/wez/wezterm/refs/heads/main/assets/shell-integration/wezterm.sh
	fi
	install_tools paru wezterm

}

function setup_terminal() {

	setup_wezterm

	install_tools pixi pre-commit
	install_tools paru dust eza fd lazygit ripgrep starship topgrade-bin zoxide tz yazi neovim git-delta

	# don't want fish to start when we install it so it get's handled separately
	if ! command -v fish &>/dev/null; then
		sudo pacman -S --needed --noconfirm fish
	fi

	# outside of home dir so stow won't manage these I think
	sudo rm /etc/pacman.conf
	sudo ln -s ~/dotfiles/pacman.conf /etc/pacman.conf -f

}

function setup_writing_tools() {

	install_tools paru evince typst zola obsidian

	#set evince as defatul pdf application
	xdg-mime default org.gnome.Evince.desktop application/pdf
	gio mime application/pdf org.gnome.Evince.desktop

}

function setup_misc_dev_tools() {
	install_tools paru github-cli just tokei gittype lazygit

}
function setup_rust_tools() {
	install_tools paru rustup taplo-cli bacon release-plz

}
function setup_infra_tools() {
	install_tools pixi awscli
}

function setup_espanso() {
	install_tools paru espanso-wayland-git
	espanso service register
}

function setup_fonts() {
	install_tools paru noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-firacode-nerd ttf-font-awesome
	mkdir -p ~/.local/share/fonts{Clicker_Script,EB_Garmond}
	curl -Ls -c -o ~/.local/share/fonts/Clicker_Script/ClickerScript-Regular.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/clickerscript/ClickerScript-Regular.ttf
	curl -Ls -c -o "$HOME/.local/share/fonts/EB_Garamond/EBGaramond-VariableFont_wght.ttf" https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf
	curl -Ls -c -o "$HOME/.local/share/fonts/EB_Garamond/EBGaramond-Italic-VariableFont_wght.ttf" https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/EBGaramond-Italic%5Bwght%5D.ttf
}

function setup_de() {
	mkdir -p ~/Wallpapers
	if [ ! -f ~/Wallpapers/wall.webp ]; then
	    curl -Ls https://raw.githubusercontent.com/gh0stzk/dotfiles/master/config/bspwm/rices/andrea/walls/wall-01.webp -o ~/Wallpapers/wall.webp
	fi 
	if [ ! -f ~/Wallpapers/locked.png ]; then
	    curl -Ls https://wallpapercave.com/wp/wp2639448.png -o ~/Wallpapers/locked.png
	fi

	sudo rm -f /etc/sddm.conf
	sudo ln -s ~/dotfiles/sddm.conf /etc/sddm.conf

	install_tools paru brightnessctl cronie gammastep grim sddm sddm-catppuccin-git slurp swappy swaybg swayidle swaylock waybar webp-pixbuf-loader xdg-desktop-portal xdg-desktop-portal thunar xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal-wlr libqalculate
	install_tools paru walker elephant elephant-symbols elephant-unicode elephant-providerlist elephant-menus elephant-calc elephant-desktopapplications

	sudo systemctl enable --now cronie.service

}

function setup_dotfiles() {
	install_tools paru stow
	if [ ! -d ~/dotfiles ]; then
		git clone https://github.com/savente93/dotfiles.git ~/dotfiles
		pushd ~/dotfiles || exit 1
		git remote set-url origin git@github.com:savente93/dotfiles.git

		# just let stow assume ownership of everything
		stow --adopt *
		git restore .

		popd || exit 1
	fi
}

function setup_1password() {

	if ! command -v 1password; then
		curl -LsS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
		install_tools paru 1password 1password-cli

		read -r -p "1Password has been installed. Please unlock it and enable the CLI. Press Enter to continue..." -s -n1 </dev/tty
		op vault list || exit 1
	fi

}

function setup_ssh() {

	install_tools paru wikiman base-devel

	install_tools paru keychain openssh openssl
	sudo systemctl enable --now ufw.service
	sudo systemctl enable --now sshd.service

	# ssh
	mkdir -p ~/.ssh
	chmod -R 700 ~/.ssh

	# add github to known hosts
	ssh-keyscan github.com >githubKey
	ssh-keygen -lf githubKey >>~/.ssh/known_hosts
	rm githubKey

	ssh-keyscan gitlab.com >gitlabKey
	ssh-keygen -lf gitlabKey >>~/.ssh/known_hosts
	rm gitlabKey

	# get sshkeys from password manager
	key_type=$(op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "key type")

	if [ -z "$key_type" ]; then
		echo "Could not determine key type..."
		exit 1
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
	echo -e "\tsigningkey = ~/.ssh/id_$key_type" >>~/.gitconfig.signingkey
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
	echo "aws_secret_access_key= $(op item get 'AWS [Personal]' --fields credential --reveal)" >>~/.aws/credentials
	install_tools paru aws-credential-1password

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
	setup_time_zone
	setup_dotfiles
	setup_terminal
	setup_espanso
	setup_fonts
	setup_audio
	setup_de
	setup_1password
	setup_ssh

}

function setup_minimal() {
	setup_common
	setup_writing_tools
}

function setup_dev() {
	setup_misc_dev_tools
	setup_rust_tools
	setup_infra_tools
	setup_1password
	setup_docker
	setup_aws
}

function setup_all() {
	setup_common
	setup_writing_tools
	setup_dev
	setup_image_processing
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
"")
	exit 1
	;;
*)
	echo "Unknown group: $group"
	exit 1
	;;
esac
