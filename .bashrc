eval $(keychain --eval --quiet -Q id_ed25519)
if [ -z "$BASH_EXECUTION_STRING" ]; then 
	exec fish 
fi
