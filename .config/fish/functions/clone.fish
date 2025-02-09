

function clone
    set -l TOKEN $(op item get "gitea-token" --fields label=credential --reveal)
    set -l BASE_URL $(op item get "Personal gitea" --fields label=url)
    set -l USERNAME $(op item get "Personal gitea" --fields label=username)


    if test -z "$TOKEN" | test -z "$BASE_URL" | test -z "git@$BASE_URL" | test -z "$USERNAME"
        echo "Could not retrieve secrets"
        return
    end

    set SELECTED_REPO $(curl -Ls "https://$BASE_URL/api/v1/users/$USERNAME/repos" -H "accept: application/json"  -H "Authorization: token $TOKEN" | jq -r "map(.name)|.[]" | fzf)

    if test -z "$SELECTED_REPO"
        echo "no repo selected"
        return
    end

    set REPO_TOPIC $(curl -Ls "https://$BASE_URL/api/v1/repos/$USERNAME/$SELECTED_REPO/topics" -H "accept: application/json"  -H "Authorization: token $TOKEN" | jq -r ".topics[0] // empty")

    if [ -z "$REPO_TOPIC" ]
        echo "repo had no topic"
        return
    end

    mkdir -p "$HOME/projects/$REPO_TOPIC"
    git clone "git@$BASE_URL:$USERNAME/$SELECTED_REPO.git" "$HOME/projects/$REPO_TOPIC/$SELECTED_REPO"

end
