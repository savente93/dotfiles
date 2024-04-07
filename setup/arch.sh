#!/bin/bash

function install_paru() {
	if [ -z command -v paru ] &>/dev/null; then
		sudo pacman -S --needed base-devel
		git clone https://aur.archlinux.org/paru.git
		cd paru
		makepkg -si
		cd ..
		rm -rf paru
		sudo paru -S paru
		paru -Syu
	fi
}

function basic_system_setup() {

	paru -S blueman iwd keychain openssl openssh xorg-server chrony base-devel ufw curl

	for s in chronyd iwd NetworkManager sshd bluetooth ufw; do
		sudo systemctl enable $s.service
		sudo systemctl start $s.service
	done

	# make sure laptop hybernates when battery is too low
	echo 'SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-7]", RUN+="/usr/bin/systemctl hibernate"' | sudo tee /etc/udev/rules.d/99-lowbat.rules

}

function setup_dev_stuff() {

	# tools
	for tool in bottom cargo-binstall dust eza fd git-delta gitleaks helix lazygit pixi ripgrep ruff starship stylua topgrade wezterm zola zoxide; do
		paru -S $tool
	done

	# runtimes/compilers
	paru -S docker opentofu-bin npm

	#LSPs/linters
	for tool in taplo-cli rust-analyzer marksman lua-language-server ruff-lsp shfmt bash-language-server dockerfile-language-server-bin yaml-language-server vscode-langservers-extracted; do
		paru -S $tool
	done

	# pixi
	pixi global install pre-commit awscli

	# currently one of the grammars in hx that I don't care about fails
	# so just continue
	helix --grammar fetch || true
	helix --grammar build || true

	cargo binstall jinja-lsp

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

}

function setup_creature_comforts() {

	paru -S discord spotify zoom teams espanso-x11

	# setup espanso
	espanso service register

	mkdir -p ~/.config/espanso
	ln -s ~/Documents/dotfiles/espanso/config ~/.config/espanso/ -f
	ln -s ~/Documents/dotfiles/espanso/match ~/.config/espanso/ -f

}

function config_de() {
	paru -S dolphin nitogen firefox flameshot i3lock i3-wm nvidia nvidia-utils polybar redshift rofi sddm ttf-firacode-nerd xss-lock brightnessctl
	mkdir -p ~/.local/bin/rofi

	# sddm theme
	sudo ln -s ~/Documents/dotfiles/sddm/sugar-dark /usr/share/sddm/themes/sugar-dark -f

	echo -e "[Theme]" >/etc/sddm.conf.d/theme.conf
	echo -e "Current=sugar-dark" >>/etc/sddm.conf.d/theme.conf

	ln -s ~/Documents/dotfiles/i3 ~/.config/ -f
	ln -s ~/Documents/dotfiles/polybar ~/.config/ -f
	ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.rasi ~/.config/rofi/ -f
	ln -s ~/Documents/dotfiles/rofi/powermenu/powermenu.sh ~/.local/bin/rofi/ -f
	ln -s ~/Documents/dotfiles/rofi/launcher/launcher.rasi ~/.config/rofi/ -f
	ln -s ~/Documents/dotfiles/rofi/launcher/launcher.sh ~/.local/bin/rofi/ -f

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
	if [ -z $(command -v 1password) ]; then
		echo "installing 1password"

		curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
		paru -S 1password 1password-cli rofi-1pass aws-credential-1password

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
