eval "$(keychain --eval --quiet -Q id_ed25519)"

if [[ $- != *i* ]]; then
	# Shell is non-interactive.  Be done now!
	return
fi

export TZ_LIST="Europe/Amsterdam,Home;America/Chicago,Wrezinsky;America/New_York,Kelly;Europe/London,Andy;Europe/London,Hannah"
export PATH="/home/sam/.pixi/bin:$PATH"
# maybe don't brick the system if fish isn't installed
# don't ask me how I know that...
if command -v fish >/dev/null 2>&1; then
	exec /usr/bin/fish
fi
