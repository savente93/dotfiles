eval "$(keychain --eval --quiet -Q id_ed25519)"

export WALKER_CONFIG_TYPE=toml

if [[ $- != *i* ]]; then
	# Shell is non-interactive.  Be done now!
	return
fi

export TZ_LIST="Europe/Amsterdam,Home;America/Chicago,Wrezinsky;America/New_York,Kelly;Europe/London,Andy;Europe/London,Hannah"
if [[ ":$PATH:" != *":$HOME/.pixi/bin:"* ]]; then
	export PATH="$PATH:$HOME/.pixi/bin"
fi
# maybe don't brick the system if fish isn't installed
# don't ask me how I know that...
if command -v fish >/dev/null 2>&1; then
	exec /usr/bin/fish
fi
