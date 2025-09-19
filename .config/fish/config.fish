if status is-interactive
    starship init fish | source
    zoxide init fish | source
    pixi completion --shell fish | source

    if test -x (command -v fw)
        if test -x (command -v sk)
            fw print-fish-setup -s | source
        else
            fw print-fish-setup | source
        end
    end

    # typing is for chumps
    abbr --add dotdot --regex '^\.\.+$' --function multicd
    abbr --add up topgrade -y --skip-notify
    abbr --add gp git push

    # root doesn't have my nice helix config
    abbr --add shx sudo hx --config $HELIX_CONFIG_PATH

    #files
    abbr --add ls eza
    abbr --add la eza -lah
    abbr --add lt eza --tree -L 2 --git-ignore -A
    abbr --add ltt eza --tree -L 3 --git-ignore -A
    abbr --add lttt eza --tree -L 4 --git-ignore -A

    # clean up empty dirs
    abbr --add ced fd . -te -td -x rmdir

    # cargo
    abbr --add ct cargo nextest run --failure-output final --all-features --no-fail-fast
    abbr --add cb cargo build
    abbr --add cc cargo check
    abbr --add newrust cargo generate --favorite rust

    #bluetooth
    abbr --add bt bluetui

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

    abbr --add fkt fk teams

    # work
    abbr --add pt pixi run -e default test-lf
    abbr --add ptt pixi run -e default test
    abbr --add pe pixi run -e default helix .
    abbr --add pi pixi run -e default ipython

    set -g fish_key_bindings fish_vi_key_bindings
end

/home/sam/.local/bin/mise activate fish | source # added by https://mise.run/fish
