function gbu
    git branch -u origin/(git rev-parse --abbrev-ref HEAD)
end
