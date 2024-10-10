function new_repo
    if count $argv >/dev/null
        # should probably do more input sanitisation here, but whatever, it's just me using it.
        set -l TOKEN $(op item get "gitea token" --fields label=credential --reveal)
        set -l BASE_URL $(op item get "Personal gitea" --fields label=url)
        set -l SSH_URL $(op item get "Personal gitea" --fields label=ssh-url)
        set -l USERNAME $(op item get "Personal gitea" --fields label=username)
        set -l REPO_NAME $argv[1]

        curl -k -H "content-type: application/json" -H "Authorization: token $TOKEN" "$BASE_URL/api/v1/user/repos" -d "{\"name\": \"$REPO_NAME\"}"
        if test -d ".git"
            # we are inside a repo so add it as a remote if it doesn't exist yet
            if not count $(git remote -v | grep origin)
                if test -n $SSH_URL && test -n $USERNAME && test -n $REPO_NAME
                    git remote add origin "$SSH_URL:$USERNAME/$REPO_NAME.git"
                    git push -u origin main
                else
                    echo "could not resolve all of variables, not adding remote"
                end
            end
        else
            echo "Please provide new repo name"
            exit 1
        end
    end
end
