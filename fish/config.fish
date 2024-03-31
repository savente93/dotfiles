if status is-interactive
    set fish_greeting

    SHELL=fish keychain --eval --quiet -Q id_ed25519 | source

    starship init fish | source
    zoxide init fish | source
    pixi completion --shell fish | source


    # typing is for chumps 
    abbr --add dotdot --regex '^\.\.+$' --function multicd
    abbr --add up topgrade -y --skip-tonify --no-retry -c 
    abbr --add hx helix

    # root doesn't have my nice helix config
    abbr --add shx sudo helix --config $HELIX_CONFIG_PATH

    #files
    abbr --add ls eza
    abbr --add la eza -lah
    abbr --add lt eza --tree -L 2
    abbr --add ltt eza --tree -L 3

    # git
    abbr --add gad git add -p
    abbr --add gst git status
    abbr --add gdm git diff main
    abbr --add gmm git merge main
    abbr --add gco git checkout
    abbr --add glo git log --graph --decorate --pretty=oneline --abbrev-commit
    abbr --add gbr git branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:blue)(%(committerdate:short)) [%(authorname)]'
    abbr --add gbd git branch -D 
    abbr --add gfp git fetch --all --prune

    # work
    abbr --add pt pixi run -e full-py39 test-lf
    abbr --add ptt pixi run -e full-py39 test
    abbr --add pe pixi run -e full-py39 hx .
    abbr --add pi pixi run -e full-py39 ipython

end

