#!/bin/bash

function install_pixi() {
	if ! command -v pixi &>/dev/null; then
		curl -fsSL https://pixi.sh/install.sh | bash
		export PATH=$PATH:$HOME/.pixi/bin
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

	echo "Installing paru..."
	if ! command -v paru &>/dev/null; then
		# because paru is in the AUR we can't install it from pacman
		# but we want to be able to update itself so we'll
		# install one version manually, then install paru through that
		# and remove the version we just installed
		if [ ! -d paru-bin ]; then
			git clone https://aur.archlinux.org/paru-bin.git
		fi
		makepkg -si --noconfirm --dir paru-bin
		rm -rf paru-bin
		paru -S bat --noconfirm
	fi

}

function install_instalation_gateways() {
	install_cargo
	install_paru
	install_pixi
	install_flatpak
}

function install_from_paru() {
	local tools=("$@")

	if [ "${#tools[@]}" -eq 0 ]; then
		return 1
	fi

	for t in "${tools[@]}"; do
		if [ -z "$(paru -Q "$t")" ]; then
			echo "$t already installed skipping..."
			return 0
		else
			paru -S "$t" --noconfirm
		fi

	done

}

function install_from_cargo() {
	local tools=("$@")

	if [ "${#tools[@]}" -eq 0 ]; then
		return 1
	fi

	for t in "${tools[@]}"; do
		if [ -z "$(cargo install --list | grep "$t")" ]; then
			echo "$t already installed skipping..."
			return 0
		else
			cargo install "$t"
		fi

	done

}

function install_from_flatpak() {
	local tools=("$@")

	if [ "${#tools[@]}" -eq 0 ]; then
		return 1
	fi

	for t in "${tools[@]}"; do
		if [ -z "$(flatpak list | grep "$1")" ]; then
			echo "$t already installed skipping..."
			return 0
		else
			flatpak install "$1" -y
		fi

	done

}

function install_from_pixi() {
	local tools=("$@")

	if [ "${#tools[@]}" -eq 0 ]; then
		return 1
	fi

	for t in "${tools[@]}"; do
		if [ -z "$(flatpak list | grep "$1")" ]; then
			echo "$t already installed skipping..."
			return 0
		else
			flatpak install "$1" -y
		fi

	done

}

function install_helix_fork() {

	if [ -f "$HOME/.cargo/bin/hx" ]; then
		echo "Helix already installed skipping..."
		return 0
	else
		echo "installing helix"
	fi

	mkdir -p ~/projects/rust

	cd ~/Documents/projects/rust
	git clone git@github.com:savente93/helix.git
	cd helix
	git checkout bin
	cargo install --path helix-term --locked

	# just in case
	rm -rf ~/.config/helix/runtime
	ln -s "$PWD"/runtime ~/.config/helix/ -f

	curl -Ssfo ~/.config/helix/themes/onedark.toml https://raw.githubusercontent.com/helix-editor/helix/master/runtime/themes/onedark.toml
	ln -s ~/Documents/dotfiles/helix/config.toml ~/.config/helix/config.toml -f
	ln -s ~/Documents/dotfiles/helix/languages.toml ~/.config/helix/languages.toml -f

	~/.cargo/bin/hx -g fetch
	~/.cargo/bin/hx -g build

}

function setup_internet() {
	nmcli d wifi connect -a "$(nmcli -f SSID d wifi list | sort | uniq | grep -v SSID | grep -o '[^[:space:]].*[^[:space:]]' | fzf --header "Please select a wifi network")"
}

function setup_audio() {
	pass
}

function setup_basic_system() {
	echo "starting basic system setup..."

	for t in "${tools[@]}"; do
		install_from_paru "$t"
	done

	install_helix_fork

	paru -S base-devel chrony curl keychain openssh openssl pipewire pipewire-pulse sway ufw --noconfirm

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

function setup_wezterm() {

	curl -Ssfo ~/.wezterm.sh https://raw.githubusercontent.com/wez/wezterm/refs/heads/main/assets/shell-integration/wezterm.sh

	tools=(wezterm stylua lua-language-server)

	install_from_paru "${tools[@]}"

}

function setup_terminal() {

	install_helix_fork
	setup_wezterm

	tools=(dust eza fd lazygit ripgrep starship topgrade-bin zoxide)
	install_from_paru "${tools[@]}"

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
	tools=(d2 zola typst typos jinja-lsp bibtex-tidy marksman texlab typst-lsp-bin evince)
	for t in "${tools[@]}"; do
		install_from_paru "$t"
	done

	#set evince as defatul pdf application
	xdg-mime default org.gnome.Evince.desktop application/pdf
	gio mime application/pdf org.gnome.Evince.desktop

	install_from_cargo "jinja-lsp"

}

function setup_python_tools() {
	tools=(pyright ruff-lsp)
	for t in "${tools[@]}"; do
		install_from_paru "$t"
	done

}

function setup_rust_tools() {
	tools=(rustup rust-analyzer taplo-cli)
	for t in "${tools[@]}"; do
		install_from_paru "$t"
	done

}

function setup_generic_dev_stuff() {

	echo "setting up dev tools"
	# tools
	for tool in cargo-binstall cargo-cache cargo-update wikiman; do
		if ! command -v $tool &>/dev/null; then
			paru -S $tool --noconfirm
		fi
	done

	echo "setting up LSPs and linters"
	#LSPs/linters
	for tool in bash-language-server shellcheck shfmt terraform-ls yaml-language-server; do
		if ! command -v $tool &>/dev/null; then
			paru -S $tool --noconfirm
		fi
	done

	echo "setting up pixi"
	# pixi
	pixi global install pre-commit awscli djlint

}

function setup_espanso() {
	paru -S flatpak espanso-wayland-git unzip --noconfirm
	espanso service register

	mkdir -p ~/.config/espanso
	rm -rf ~/.config/espanso/*
	ln -s ~/Documents/dotfiles/espanso/config ~/.config/espanso/ -f
	ln -s ~/Documents/dotfiles/espanso/match ~/.config/espanso/ -f
}

function setup_creature_comforts() {

	echo "setting up creature comforts"
	paru -S flatpak espanso-wayland-git unzip --noconfirm

	flatpak install -y com.spotify.Client

}

function setup_de() {
	paru -S acpi brightnessctl cronie dunst evince firefox gammastep grim lxappearance mesa noto-fonts noto-fonts-cjk pulsemixer noto-fonts-emoji pipewire pipewire-audio qpwgraph sddm sddm-catppuccin-git slurp swappy swaybg swayidle swaylock ttf-firacode-nerd ttf-font-awesome tz waybar webp-pixbuf-loader wireplumber xdg-desktop-portal xdg-desktop-portal thunar xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal-wlr yazi --noconfirm
	mkdir -p ~/{.local/bin,.config}/rofi
	mkdir -p ~/Wallpapers
	curl https://raw.githubusercontent.com/gh0stzk/dotfiles/master/config/bspwm/rices/andrea/walls/wall-01.webp -o ~/Wallpapers/wall.webp
	curl https://wallpapercave.com/wp/wp2639448.png -o ~/Wallpapers/locked.png

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
	install_from_paru stow
	if [ ! -d ~/dotfiles ]; then
		git clone https://github.com/savente93/dotfiles.git ~/dotfiles
		pushd ~/dotfiles
		git remote set-url origin git@github.com:savente93/dotfiles.git
		stow .
		popd
	fi
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
	bootstrap_paru
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
