if status is-interactive
    starship init fish | source
    zoxide init fish | source
    pixi completion --shell fish | source


    # typing is for chumps
    abbr --add dotdot --regex '^\.\.+$' --function multicd
    abbr --add up topgrade -y --skip-notify
    abbr --add gp git push

    # root doesn't have my nice helix config
    abbr --add shx sudo hx --config $HELIX_CONFIG_PATH

    #files
    abbr --add ls eza
    abbr --add la eza -lah
    abbr --add lt eza --tree -L 2
    abbr --add ltt eza --tree -L 3
    # clean up empty dirs
    abbr --add ced fd . -te -td -x rmdir

    # cargo 
    abbr --add ct cargo nextest run
    abbr --add cb cargo build
    abbr --add cc cargo check
    abbr --add b bacon

    # git
    abbr --add gad git add -p
    abbr --add gst git status
    abbr --add gdm git diff main
    abbr --add gmm git merge main
    abbr --add gco git checkout
    abbr --add glo git log --graph --decorate --pretty=oneline --abbrev-commit
    abbr --add gu gitui

    # fish keeps trying to steal my quotes >:(
    abbr --add gbr -- git branch --format='\'%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:blue)(%(committerdate:short)) [%(authorname)]\''

    abbr --add gbd git branch -D
    abbr --add gfp git fetch --all --prune

    # work
    abbr --add pt pixi run -e default test-lf
    abbr --add ptt pixi run -e default test
    abbr --add pe pixi run -e default helix .
    abbr --add pi pixi run -e default ipython

end
