#!/bin/bash

# setup_* are the top level funcs

function setup_os() {

	update_apt

	if [ $(hostname) = 'pop-os' ]; then
		# every machine being called "pop-os" is a little confusing
		read -p "Enter new hostname: " hname </dev/tty
		sudo hostnamectl set-hostname $hname
	fi

	setup_security
	setup_package_managers
	setup_dev_stuff
	setup_creature_comforts

}

function setup_package_managers() {
	echo "installing package managers..."
	# "package" managers
	# i.e. anything that can install stuff

	# homebrew
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# mise en place
	curl https://mise.jdx.dev/install.sh | sh
	eval "$(~/.local/bin/mise activate zsh)"

	# pixi
	curl -fsSL https://pixi.sh/install.sh | bash

	# flatpak
	sudo apt install -y flatpak

	# rustup
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -- -y
	source ~/.cargo/env

	echo "Done"

}

function setup_dev_stuff() {
	echo "installing dev tools"

	config_dotfiles_and_dirs

	# mise
	mise use nodejs@latest go@latest julia@latest --global
	mise plugin install awscli --global

	# homebrew
	brew tap wez/wezterm-linuxbrew
	brew install wezterm
	brew install zola
	brew install marksman
	brew install gitleaks
	brew install opentofu

	# pixi
	pixi global install pre-commit
	pixi global install ruff
	pixi global install mamba
	pixi global install ruff-lsp
	pixi global install grayskull
	pixi global install quarto

	# LSPs
	hx --grammar build
	rustup component add rust-analyzer
	mise plugin install lua-language-server@latest --global
	cargo install taplo-cli --locked --features lsp,toml-test

	cargo binstall stylua jinja-lsp
	go install github.com/go-delve/delve/cmd/dlv@latest golang.org/x/tools/gopls@latest mvdan.cc/sh/v3/cmd/shfmt@latest

	npm i -g bash-language-server
	npm i -g dockerfile-language-server-nodejs
	npm i -g svelte-language-server
	npm i -g yaml-language-server@next
	npm i -g pyright

	# html, css & json
	npm i -g vscode-langservers-extracted

	# misc
	install_docker

	echo "Done"

}

function setup_creature_comforts() {

	echo "installing creature comforts"

	setup_dotfiles_and_dirs
	setup_zsh

	cargo install cargo-binstall
	cargo binstall bottom cargo-cache cargo-update du-dust eza fd-find git-delta ripgrep starship topgrade ttyper zoxide -y

	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --noninteractive --user \
		com.github.IsmaelMartinez.teams_for_linux \
		com.discordapp.Discord \
		com.spotify.Client \
		us.zoom.Zoom

	install_fonts

	setup_de

	echo "Done"

}

function setup_security() {

	echo "setting up secruity"

	# install password manager
	# installing through the deb will setup apt et al for us
	curl https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb -o 1password.deb -L
	sudo dpkg install 1password.deb
	rm 1password.deb

	mkdir -p $AUTOSTART
	# autostart 1password at login
	echo -e "[Desktop Entry]\nType=Application\nExec=/usr/bin/1password --silent\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_GB]=1Password\nName=1Password\nComment[en_GB]=\nComment=" >~/.config/autostart/1password.desktop

	read -p "1Password has been installed. Please unlock it and enable the CLI. Press Enter to continue..." -s -n1 </dev/tty

	# disable root login
	sudo sed -i -E 's/root:x:0:0:root:\/root:\/bin\/bash/root:x:0:0:root:\/root:\/usr\/sbin\/nologin/' /etc/passwd

	# ssh
	chmod -R 755 ~

	# ssh is pretty fussy about permissions
	mkdir ~/.ssh
	chmod 700 ~/.ssh

	key_type=$(op item get "$(hostname) [ssh]" --fields "key type")

	echo "$(op item get "$(hostname) [ssh]" --fields "public key")" >>~/.ssh/$key_type.pub
	chmod 644 ~/.ssh/$key_type.pub

	echo "$(op item get "$(hostname) [ssh]" --fields "private key" --reveal)" >>~/.ssh/$key_type
	chmod 600 ~/.ssh/$key_type

	# ssh connections only allowed through non root key based auth
	sudo sed -i -E "s/[#]?PasswordAuthentication (yes|no)/PasswordAuthentication no/;s/#?PubkeyAuthentication (yes|no)/PubkeyAuthentication yes/;s/#?PermitRootLogin (yes|no)/PermitRootLogin no/;s/#?AllowUsers .*/AllowUsers $USER/" /etc/ssh/sshd_config
	sudo systemctl restart sshd.service

	# allow ssh connections
	sudo ufw enable
	sudo ufw allow OpenSSH

	# git by using the signing key each machine can have it's own key but still have a common gitconfig
	echo "[user]" >~/.gitconfig.signingkey
	echo "\tsigningkey = $(op item get "$(hostname) [ssh]" --fields "public key")" >>~/.gitconfig.signingkey

	# aws cli
	mkdir -p ~/.aws
	echo -e "[default]\n\t" >~/.aws/credentials
	echo "aws_access_key_id = $(op item get 'AWS [Personal]' --fields username)" >>~/.aws/credentials
	echo "aws_secret_access_key= $(op item get 'AWS [Personal]' --fields credential)" >>~/.aws/credentials

	echo "Done"

}

####################
# Helper functions #
####################

function update_apt() {

	# the usual stuff
	sudo apt update &&
		sudo apt -y --allow-downgrades dist-upgrade &&
		sudo apt install \
			ca-certificates \
			curl \
			openssh-server &&
		sudo apt -y autoremove &&
		sudo apt -y autoclean

}

function config_de() {
	# still learning how to configure kde non-interactively so very sparse
	sudo apt install -y kde-standard sddm

	# dark theme pls
	lookandfeeltool -a org.kde.breezedark.desktop
}

function config_dotfiles_and_dirs() {
	git clone $DOTFILE_REPO $DOTFILES
	git clone $SETUP_REPO $SETUPS
	git clone $PRIVATE_REPO $PRIVATE

	#setup all dirs we'll need later
	mkdir -p ~/.config/{helix,espanso}
	mkdir -p ~/.local/bin
	mkdir -p ~/Documents/projects

	# setup symlinks
	ln -s $DOTFILES/helix/config.toml ~/.config/helix/config.toml
	ln -s $DOTFILES/helix/languages.toml ~/.config/helix/languages.toml
	ln -s $DOTFILES/.wezterm.lua ~/.wezterm.lua
	ln -s $DOTFILES/.wezterm.sh ~/.wezterm.sh
	ln -s $DOTFILES/.gitignore ~/.gitignore
	ln -s $DOTFILES/.gitconfig ~/.gitconfig
	ln -s $DOTFILES/starship.toml ~/.config/starship.toml
	ln -s $DOTFILES/topgrade.toml ~/.config/topgrade.toml
	ln -s $DOTFILES/espanso/config ~/.config/espanso/config
	ln -s $DOTFILES/espanso/match ~/.config/espanso/match
}

function config_zsh() {

	echo "setting up zsh plugins"
	chsh -s $(which zsh)
	mkdir -p ~/.zsh/plugins
	[[ -d ~/.zsh/plugins/fast-syntax-highlighting ]] || git clone https://github.com/zdharma-zmirror/fast-syntax-highlighting.git ~/.zsh/plugins/fast-syntax-highlighting

}

function install_docker() {

	# Add Docker's official GPG key:
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" |
		sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	# add self to docker group so we can run docker ourselves
	sudo usermod -aG docker $USER

}

function install_fonts() {

	mkdir -p ~/.local/share/fonts
	cd ~/.local/share/fonts
	curl https://github.com/ryanoasis/nerd-fonts/releases/download/latest/FiraCode.zip -o FiraCode.zip -L
	unzip FiraCode.zip
	rm FiraCode.zip LICENSE readme.md
	fc-cache -f

}
