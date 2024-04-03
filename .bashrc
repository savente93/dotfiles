eval $(keychain --eval --quiet -Q id_ed25519)

if [[ $- != *i* ]]; then
	# Shell is non-interactive.  Be done now!
	return
fi

exec /usr/bin/fish
