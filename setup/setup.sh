#!/bin/bash

function setup_internet() {
	nmcli d wifi connect -a "$(nmcli -f SSID d wifi list | sort | uniq | grep -v SSID | xargs | fzf --header "Please select a wifi network")"

}

function install_paru() {
	echo "Installing paru..."
	if ! command -v paru &>/dev/null; then
		sudo pacman -S --needed base-devel rustup --noconfirm
		rustup default stable
		if [ ! -d paru ]; then
			git clone https://aur.archlinux.org/paru.git
		fi
		cd paru
		makepkg -si --noconfirm
		cd ..
		rm -rf paru
		paru -S paru bat --noconfirm
		paru -Syu --noconfirm
	fi
}

function setup_basic_system() {
	echo "starting basic system setup..."

	paru -S base-devel blueman chrony curl wofi keychain openssh openssl pipewire pipewire-pulse sway ufw xorg-server-xwayland nm-connection-editor --noconfirm

	echo "installing fish"
	# don't want fish to start when we install it so it get's handled seperately
	sudo pacman -S --needed --noconfirm fish

	timedatectl set-timezone Europe/Amsterdam

	for s in NetworkManager bluetooth chronyd sshd ufw; do
		sudo systemctl enable --now $s.service
	done

	systemctl enable --now --user pipewire-pulse

	# make sure laptop hybernates when battery is too low
	echo 'SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-7]", RUN+="/usr/bin/systemctl hibernate"' | sudo tee /etc/udev/rules.d/99-lowbat.rules

}

function setup_dev_stuff() {

	echo "setting up dev tools"
	# tools
	for tool in bottom cargo-audit cargo-binstall cargo-cache cargo-tarpaulin cargo-update d2 difftastic dust eza fd git-delta lazygit ripgrep ruff rustup starship stylua topgrade-bin wikiman wezterm zola zoxide; do
		if ! command -v $tool &>/dev/null; then
			paru -S $tool --noconfirm
		fi
	done

	curl -fsSL https://pixi.sh/install.sh | bash
	export PATH=$PATH:$HOME/.pixi/bin
	rustup default stable

	echo "setting up docker & npm"
	# runtimes/compilers
	sudo pacman -S --needed --noconfirm docker npm
	sudo usermod -aG docker sam
	if [ -z "$(getent group docker)" ]; then
		newgrp docker
	fi

	sudo systemctl enable --now docker.service

	paru -S docker-compose --noconfirm

	sudo npm i -g dockerfile-language-server-nodejs
	cargo install jinja-lsp

	echo "setting up LSPs and linters"
	#LSPs/linters
	for tool in bash-language-server bibtex-tidy lua-language-server marksman pyright ruff-lsp rust-analyzer shellcheck shfmt stylua taplo-cli terraform-ls texlab yaml-language-server typst-lsp-bin; do
		if ! command -v $tool &>/dev/null; then
			paru -S $tool --noconfirm
		fi
	done

	echo "setting up pixi"
	# pixi
	pixi global install pre-commit awscli djlint

	curl -Ssfo ~/.wezterm.sh https://raw.githubusercontent.com/wez/wezterm/refs/heads/main/assets/shell-integration/wezterm.sh

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

function install_helix_fork() {
	echo "installing helix"

	mkdir -p ~/Documents/projects/rust
	mkdir -p ~/.config/helix

	cd ~/Documents/projects/rust
	git clone git@github.com:savente93/helix.git
	cd helix
	git checkout bin
	cargo install --path helix-term --locked
	# just in case
	rm -rf ~/.config/helix/runtime
	ln -s "$PWD"/runtime ~/.config/helix/ -f

	mkdir ~/.config/helix/themes
	mkdir -p ~/.cargo/bin/runtime
	curl -Ssfo ~/.config/helix/themes/onedark.toml https://raw.githubusercontent.com/helix-editor/helix/master/runtime/themes/onedark.toml
	ln -s ~/Documents/dotfiles/helix/config.toml ~/.config/helix/config.toml -f
	ln -s ~/Documents/dotfiles/helix/languages.toml ~/.config/helix/languages.toml -f

	~/.cargo/bin/hx -g fetch
	~/.cargo/bin/hx -g build

}

function setup_creature_comforts() {

	echo "setting up creature comforts"
	paru -S flatpak steam-devices-git espanso-wayland-git unzip --noconfirm

	flatpak install -y com.discordapp.Discord
	flatpak install -y com.github.IsmaelMartinez.teams_for_linux
	flatpak install -y com.spotify.Client
	flatpak install -y com.valvesoftware.Steam

	# setup espanso
	espanso service register

	mkdir -p ~/.config/espanso
	rm -rf ~/.config/espanso/*
	ln -s ~/Documents/dotfiles/espanso/config ~/.config/espanso/ -f
	ln -s ~/Documents/dotfiles/espanso/match ~/.config/espanso/ -f

}

function setup_de() {
	paru -S acpi brightnessctl cronie dunst evince firefox gammastep grim lxappearance mesa noto-fonts noto-fonts-cjk pulsemixer noto-fonts-emoji pipewire pipewire-audio qpwgraph sddm sddm-catppuccin-git slurp swappy swaybg swayidle swaylock ttf-firacode-nerd ttf-font-awesome tz waybar webp-pixbuf-loader wireplumber xdg-desktop-portal xdg-desktop-portal thunar xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal-wlr yazi --noconfirm
	mkdir -p ~/{.local/bin,.config}/rofi
	mkdir -p ~/Wallpapers
	curl https://raw.githubusercontent.com/gh0stzk/dotfiles/master/config/bspwm/rices/andrea/walls/wall-01.webp -o ~/Wallpapers/wall.webp
	curl https://wallpapercave.com/wp/wp2639448.png -o ~/Wallpapers/locked.png

	#set evince as defatul pdf application
	xdg-mime default org.gnome.Evince.desktop application/pdf
	gio mime application/pdf org.gnome.Evince.desktop
	systemctl --user --now enable wireplumber

	rm -rf ~/.config/sway
	ln -s ~/Documents/dotfiles/sway ~/.config/ -f
	rm -rf ~/.config/waybar
	ln -s ~/Documents/dotfiles/waybar ~/.config/ -f
	sudo mkdir -p /usr/share/rofi/themes/
	sudo ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.rasi /usr/share/rofi/themes/powermenu.rasi -f
	sudo ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.rasi ~/.config/rofi/powermenu.rasi -f
	ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.sh ~/.local/bin/rofi/ -f
	ln -s ~/Documents/dotfiles/rofi/launcher/launcher.rasi ~/.config/rofi/ -f
	sudo ln -s ~/Documents/dotfiles/rofi/launcher/launcher.rasi /usr/share/rofi/themes/launcher.rasi -f
	ln -s ~/Documents/dotfiles/rofi/launcher/launcher.sh ~/.local/bin/rofi/ -f
	sudo ln -s ~/Documents/dotfiles/sddm.conf /etc/ -f

}

function setup_dotfiles() {
	if [ ! -d ~/Documents/dotfiles ]; then
		git clone https://github.com/savente93/dotfiles.git ~/Documents/dotfiles
		pushd ~/Documents/dotfiles
		git remote set-url origin git@github.com:savente93/dotfiles.git
		popd
	fi
	mkdir -p ~/Documents/projects
}

function setup_security() {

	echo "setting up secruity"

	# install password manager
	# installing through the deb will setup apt et al for us
	if ! command -v 1password; then
		echo "installing 1password"

		curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
		paru -S 1password 1password-cli rofi-1pass aws-credential-1password --noconfirm

		read -r -p "1Password has been installed. Please unlock it and enable the CLI. Press Enter to continue..." -s -n1 </dev/tty
		op vault list
	fi

	mkdir -p ~/.config/autostart
	if [ ! -f ~/.config/autostart/1password.desktop ]; then
		echo "creating 1password autostart"
		mkdir -p ~/.config/autostart
		# autostart 1password at login
		echo -e "[Desktop Entry]\nType=Application\nExec=/usr/bin/1password --silent\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_GB]=1Password\nName=1Password\nComment[en_GB]=\nComment=" >~/.config/autostart/1password.desktop
	fi

	echo "disabling root login"
	# disable root login
	sudo sed -i -E 's/root:x:0:0:root:\/root:\/bin\/bash/root:x:0:0:root:\/root:\/usr\/sbin\/nologin/' /etc/passwd

	# ssh
	echo "setting up ssh identities"
	mkdir -p ~/.ssh
	chmod -R 700 ~/.ssh

	# add github to known hosts
	ssh-keyscan github.com >githubKey
	ssh-keygen -lf githubKey >>~/.ssh/known_hosts
	rm githubKey

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

	echo "configing ssh"
	# ssh connections only allowed through non root key based auth
	sudo sed -i -E "s/[#]?PasswordAuthentication (yes|no)/PasswordAuthentication no/;s/#?PubkeyAuthentication (yes|no)/PubkeyAuthentication yes/;s/#?PermitRootLogin (yes|no)/PermitRootLogin no/;s/#?AllowUsers .*/AllowUsers $USER/" /etc/ssh/sshd_config

	# allow ssh connections
	sudo ufw enable
	sudo ufw allow ssh

	# git by using the signing key each machine can have it's own key but still have a common gitconfig
	echo "[user]" >~/.gitconfig.signingkey
	echo -e "\tsigningkey = $(op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "public key")" >>~/.gitconfig.signingkey

	# aws cli
	mkdir -p ~/.aws
	echo -e "[default]\n\t" >~/.aws/credentials
	echo "aws_access_key_id = $(op item get 'AWS [Personal]' --fields username)" >>~/.aws/credentials
	echo "aws_secret_access_key= $(op item get 'AWS [Personal]' --fields credential)" >>~/.aws/credentials

	echo "Done"

}

function all() {
	setup_internet
	install_paru
	setup_basic_system
	setup_dotfiles
	setup_dev_stuff
	setup_creature_comforts
	setup_de
	setup_security
	install_helix_fork
}

# exit on error
set -e

#get sudo rights for when we need it
sudo -v

all
