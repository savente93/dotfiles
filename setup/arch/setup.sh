#!/bin/bash

function install_paru() {
	if ! command -v paru &>/dev/null; then
		sudo pacman -S --needed base-devel
		git clone https://aur.archlinux.org/paru.git
		cd paru
		makepkg -si
		cd ..
		rm -rf paru
		sudo paru -S paru bat
		paru -Syu --noconfirm
	fi
}

function basic_system_setup() {

	paru -S base-devel blueman chrony curl dmenu fish keychain openssh openssl pipewire ufw nm-connection-editor xorg-server --noconfirm

	timedatectl set-timezone Europe/Amsterdam

	for s in NetworkManager bluetooth chronyd sshd ufw pulseaudio; do
		sudo systemctl enable $s.service
		sudo systemctl start $s.service
	done

	# make sure laptop hybernates when battery is too low
	echo 'SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-7]", RUN+="/usr/bin/systemctl hibernate"' | sudo tee /etc/udev/rules.d/99-lowbat.rules

}

function setup_dev_stuff() {

	# tools
	for tool in bottom cargo-binstall cargo-cache difftastic dust eza fd git-delta gitui helix pixi ripgrep ruff starship stylua topgrade wezterm zola zoxide; do
		if ! command -v $tool; then
			paru -S $tool --noconfirm
		fi
	done

	# runtimes/compilers
	paru -S docker npm --noconfirm
	sudo groupadd docker
	sudo usermod -aG docker sam
	newgrp docker
	sudo systemctl enable docker.service
	sudo systemctl start docker.service

	#LSPs/linters
	for tool in lua-language-server marksman ruff-lsp rust-analyzer shfmt yaml-language-server bash-language-server taplo-cli; do
		if ! command -v $tool; then
			paru -S $tool --noconfirm
		fi
	done

	# pixi
	pixi global install pre-commit awscli

	# currently one of the grammars in hx that I don't care about fails
	# so just continue
	helix --grammar fetch || true
	helix --grammar build || true

	mkdir -p ~/.config/helix
	ln -s ~/Documents/dotfiles/helix/config.toml ~/.config/helix/config.toml -f
	ln -s ~/Documents/dotfiles/helix/languages.toml ~/.config/helix/languages.toml -f
	ln -s ~/Documents/dotfiles/.wezterm.lua ~/.wezterm.lua -f
	ln -s ~/Documents/dotfiles/.bashrc ~/.bashrc -f
	ln -s ~/Documents/dotfiles/.gitignore ~/.gitignore -f
	ln -s ~/Documents/dotfiles/.gitconfig ~/.gitconfig -f
	ln -s ~/Documents/dotfiles/starship.toml ~/.config/starship.toml -f
	ln -s ~/Documents/dotfiles/topgrade.toml ~/.config/topgrade.toml -f
	ln -s ~/Documents/dotfiles/fish ~/.config/ -f
	ln -s ~/Documents/dotfiles/paru/ ~/.config/ -f
	ln -s ~/Documents/dotfiles/pacman.conf /etc/pacman.conf -f

}

function setup_creature_comforts() {

	paru -S discord spotify zoom teams espanso-x11 --noconfirm

	# setup espanso
	espanso service register

	mkdir -p ~/.config/espanso
	ln -s ~/Documents/dotfiles/espanso/config ~/.config/espanso/ -f
	ln -s ~/Documents/dotfiles/espanso/match ~/.config/espanso/ -f

}

function config_de() {
	sudo paru -S brightnessctl feh firefox flameshot i3-wm i3lock mesa pipewire pipewire-audio pipewire-pulse pulsemixer polybar qpwgraph redshift rofi rofi-bluetooth-git sddm sddm-catppuccin-git ttf-firacode-nerd ttf-font-awesome tz wireplumber xorg-xinput xss-lock yazi --noconfirm
	mkdir -p ~/{.local/bin,.config}/rofi
	mkdir -p ~/Wallpapers
	curl https://raw.githubusercontent.com/gh0stzk/dotfiles/master/config/bspwm/rices/andrea/walls/wall-01.webp -o ~/Wallpapers/wall.webp
	curl https://wallpapercave.com/wp/wp2639448.png -o ~/.wallpapers/locked.png

	rm -rf ~/.config/i3
	ln -s ~/Documents/dotfiles/i3 ~/.config/ -f
	rm -rf ~/.config/polybar
	ln -s ~/Documents/dotfiles/polybar ~/.config/ -f
	sudo ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.rasi /usr/share/rofi/themes/powermenu.rasi -f
	sudo ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.rasi ~/.config/rofi/powermenu.rasi -f
	ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.sh ~/.local/bin/rofi/ -f
	ln -s ~/Documents/dotfiles/rofi/launcher/launcher.rasi ~/.config/rofi/ -f
	sudo ln -s ~/Documents/dotfiles/rofi/launcher/launcher.rasi /usr/share/rofi/themes/launcher.rasi -f
	ln -s ~/Documents/dotfiles/rofi/launcher/launcher.sh ~/.local/bin/rofi/ -f
	sudo ln -s ~/Documents/dotfiles/sddm.conf /etc/

}

function clone_dotfiles() {
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

		read -p "1Password has been installed. Please unlock it and enable the CLI. Press Enter to continue..." -s -n1 </dev/tty
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

	if [ -z $key_type ]; then
		echo "Could not determine key type..."
		return 1
	fi

	echo "$(op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "public key")" >~/.ssh/id_$key_type.pub
	chmod 644 ~/.ssh/id_$key_type.pub

	# wooooooow libcrypto is a fussy bitch
	echo "$(op item get "$(hostnamectl | grep hostname | awk '{print$3}') [ssh]" --fields "private key" --reveal | tr -d '"' | tr -d "\r" | sed -r '/^\s*$/d')" >~/.ssh/id_$key_type
	chmod 600 ~/.ssh/id_$key_type

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
	install_paru
	basic_system_setup
	clone_dotfiles
	setup_dev_stuff
	setup_creature_comforts
	config_de
	setup_security
}
