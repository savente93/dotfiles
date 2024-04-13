eval $(keychain --eval --quiet -Q id_ed25519)

if [[ $- != *i* ]]; then
	# Shell is non-interactive.  Be done now!
	return
fi

export TZ_LIST="Europe/Amsterdam,Home;America/Chicago,Wrezinsky;America/New_York,Kelly;Europe/London,Andy;Europe/London,Jess"
# maybe don't brick the system if fish isn't installed
# don't ask me how I know that...
if command -v fish 2>&1 >/dev/null; then
	exec /usr/bin/fish
fi
