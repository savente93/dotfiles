#!/bin/bash

# setup_* are the top level funcs
# TODO: Pixi is still not found, and op-ssh setup doesn't work yet for unknown reason

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
	if [ -z $(command -v brew) ]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.zprofile
		echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
	fi

	if [ -z $(command -v mise) ]; then
		# mise en place
		curl https://mise.jdx.dev/install.sh | sh
		eval "$(~/.local/bin/mise activate bash)"
		echo 'eval "$(~/.local/bin/mise activate zsh)"' >>~/.zprofile
		echo 'eval "$(~/.local/bin/mise activate bash)"' >>~/.bashrc
	fi

	if [ -z $(command -v pixi) ]; then
		# pixi
		curl -fsSL https://pixi.sh/install.sh | bash
		export PATH=/home/sam/.pixi/bin/pixi:$PATH
		echo 'export PATH=$PATH:/home/sam/.pixi/bin' >>~/.zprofile
		echo 'export PATH=$PATH:/home/sam/.pixi/bin' >>~/.bashrc

	fi

	if [ -z $(command -v flatpak) ]; then
		# flatpak
		sudo apt-get install flatpak -y
	fi

	if [ -z $(command -v rustup) ]; then
		# rustup
		curl -Lo install-rustup.sh --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs
		chmod +x ./install-rustup.sh
		./install-rustup.sh -y
		rm ./install-rustup.sh
		source ~/.cargo/env
	fi

	echo "Done"

}

function setup_dev_stuff() {
	echo "installing dev tools"

	config_dotfiles_and_dirs

	# mise
	mise use nodejs@latest go@latest julia@latest --global -y
	mise plugin install awscli -y
	mise plugin install lua-language-server -y
	eval "$(~/.local/bin/mise activate bash)"

	# homebrew
	brew tap wez/wezterm-linuxbrew
	brew install wezterm
	# add icon for desktop entry
	mkdir -p ~/.icons
	curl -Lo ~/.icons/wezterm https://raw.githubusercontent.com/wez/wezterm/main/assets/icon/wezterm-icon.svg
	curl -scurl -sf https://raw.githubusercontent.com/wez/wezterm/main/assets/wezterm.desktop | sed 's/^Icon.*/Icon=wezterm/;s/^TryExec=.*/TryExec=\/home\/linuxbrew\/.linuxbrew\/bin\/wezterm/;s/^Exec=.*/Exec=\/home\/linuxbrew\/.linuxbrew\/bin\/wezterm start --cwd \./' >wezterm.desktop
	sudo desktop-file-install --delete-original wezterm.desktop

	brew install zola
	brew install marksman
	brew install gitleaks
	brew install opentofu
	brew install helix

	# pixi
	/home/$USER/.pixi/bin/pixi global install pre-commit
	/home/$USER/.pixi/bin/pixi global install ruff
	/home/$USER/.pixi/bin/pixi global install mamba
	/home/$USER/.pixi/bin/pixi global install ruff-lsp
	/home/$USER/.pixi/bin/pixi global install grayskull
	/home/$USER/.pixi/bin/pixi global install quarto
	/home/$USER/.pixi/bin/pixi global install djlint

	# LSPs
	# currently one of the grammars in hx that I don't care about fails
	# so just continue
	hx --grammar fetch || true
	hx --grammar build || true
	rustup component add rust-analyzer
	cargo install taplo-cli --locked --features lsp,toml-test

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

	config_dotfiles_and_dirs
	config_zsh

	cargo install cargo-binstall
	cargo binstall bottom cargo-cache cargo-update du-dust eza fd-find git-delta jinja-lsp ripgrep starship stylua topgrade ttyper zoxide -y

	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --noninteractive --user \
		com.github.IsmaelMartinez.teams_for_linux \
		com.discordapp.Discord \
		com.spotify.Client \
		us.zoom.Zoom

	# install espanso 
	wget https://github.com/federico-terzi/espanso/releases/download/v2.2.1/espanso-debian-x11-amd64.deb
	sudo apt install ./espanso-debian-x11-amd64.deb
	rm ./espanso-debian-x11-amd64.deb
	espanso service register
	espanso start
	install_fonts

	config_de

	echo "Done"

}

function setup_security() {

	echo "setting up secruity"

	# install password manager
	# installing through the deb will setup apt et al for us
	if [ -z $(command -v 1password) ]; then
		echo "installing 1password"
		curl https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb -o 1password.deb -L
		sudo apt install ./1password.deb -y
		rm ./1password.deb

		curl -Lo 1password-cli.deb https://downloads.1password.com/linux/debian/amd64/stable/1password-cli-amd64-latest.deb
		sudo apt install ./1password-cli.deb -y
		rm ./1password-cli.deb

		read -p "1Password has been installed. Please unlock it and enable the CLI. Press Enter to continue..." -s -n1 </dev/tty
		op vault list
	fi

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
	chmod -R 755 ~

	if [ -z "$SSH_AUTH_SOCK" ]; then
		eval "$(ssh-agent -s)"
	fi

	# ssh is pretty fussy about permissions
	ssh-add -l # check for keys
	if [ $? -ne 0 ]; then
		echo "setting up ssh identities"
		mkdir -p ~/.ssh
		chmod -R 700 ~/.ssh

		# add github to known hosts
		ssh-keyscan github.com >githubKey
		ssh-keygen -lf githubKey >>~/.ssh/known_hosts
		rm githubKey

		# get sshkeys from password manager
		key_type=$(op item get "$(hostname) [ssh]" --fields "key type")

		if [ -z $key_type ]; then
			echo "Could not determine key type..."
			return 1
		fi

		echo "$(op item get "$(hostname) [ssh]" --fields "public key")" >~/.ssh/id_$key_type.pub
		chmod 644 ~/.ssh/id_$key_type.pub

		# wooooooow libcrypto is a fussy bitch
		echo "$(op item get "$(hostname) [ssh]" --fields "private key" --reveal | tr -d '"' | tr -d "\r" | sed -r '/^\s*$/d')" >~/.ssh/id_$key_type
		chmod 600 ~/.ssh/id_$key_type

		echo "Host *" >~/.ssh/config
		echo "IdentityFile ~/.ssh/id_$key_type" >>~/.ssh/config

	fi

	echo "configing ssh"
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
	sudo apt-get update &&
		sudo apt-get -y --allow-downgrades dist-upgrade &&
		sudo apt-get install \
			ca-certificates \
			curl \
			libssl-dev \
			openssh-server \
			openssl \
			pkg-config \
			zsh &&
		sudo apt-get -y autoremove &&
		sudo apt-get -y autoclean

}

function config_de() {
	# still learning how to configure kde non-interactively so very sparse
	sudo apt-get install -y kde-standard sddm

	# dark theme pls
	lookandfeeltool -a org.kde.breezedark.desktop

	# disable the virtual keyboard at startup
	sudo touch /etc/sddm.conf
	echo "InputMethod=" | sudo tee -a /etc/sddm.conf
}

function config_dotfiles_and_dirs() {
	if [ ! -d ~/Documents/dotfiles ]; then
		git clone https://github.com/savente93/dotfiles.git ~/Documents/dotfiles
		pushd ~/Documents/dotfiles
		git remote set-url origin git@github.com:savente93/dotfiles.git
		popd
	fi

	#setup all dirs we'll need later
	mkdir -p ~/.config/{helix,espanso}
	mkdir -p ~/.local/bin
	mkdir -p ~/Documents/projects

	# setup symlinks
	ln -s ~/Documents/dotfiles/helix/config.toml ~/.config/helix/config.toml -f
	ln -s ~/Documents/dotfiles/helix/languages.toml ~/.config/helix/languages.toml -f
	ln -s ~/Documents/dotfiles/.wezterm.lua ~/.wezterm.lua -f
	ln -s ~/Documents/dotfiles/.zshrc ~/.zshrc -f
	ln -s ~/Documents/dotfiles/.wezterm.sh ~/.wezterm.sh -f
	ln -s ~/Documents/dotfiles/.gitignore ~/.gitignore -f
	ln -s ~/Documents/dotfiles/.gitconfig ~/.gitconfig -f
	ln -s ~/Documents/dotfiles/starship.toml ~/.config/starship.toml -f
	ln -s ~/Documents/dotfiles/topgrade.toml ~/.config/topgrade.toml -f
	ln -s ~/Documents/dotfiles/espanso/config ~/.config/espanso/config -f
	ln -s ~/Documents/dotfiles/espanso/match ~/.config/espanso/match -f
}

function config_zsh() {

	echo "setting up zsh plugins"
	chsh sam -s $(which zsh)
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
	sudo apt-get update -y
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

	# add self to docker group so we can run docker ourselves
	sudo usermod -aG docker $USER

}

function install_fonts() {

	mkdir -p ~/.local/share/fonts
	pushd ~/.local/share/fonts
	curl https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.tar.xz -Lsfo FiraCode.tar.xz
	tar xf FiraCode.tar.xz
	rm FiraCode.tar.xz LICENSE readme.md
	fc-cache -f
	popd

}
