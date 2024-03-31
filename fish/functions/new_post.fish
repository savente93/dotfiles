function new_post
    set INPUT $argv[1]
    set INPUT_SAFE (string replace -a ' ' '-' $argv[1] | string replace -a -r "[^a-zA-Z0-9\-]" "" | string lower)
    set DIR (realpath (fd unpublished | head -n 1))
    set FILE_PATH "$DIR/INPUT_SAFE/index.md"

    if test -d $DIR 
        echo "could not find unpublished content folder. Are you in the correct root?"
        return 1
    end

    if test -f $FILE_PATH
        echo "File already exists. exiting..."
        return 1
    end

	mkdir -p $DIR/$INPUT_SAFE

# 	# start with front matter
	echo "+++
title=\"$INPUT\"
date=$(date --iso)
draft=true
[taxonomies]
tags=[\"wip\"]
+++
    " >>$FILE_PATH

	# open up to write down ideas
	EDITOR $FILE_PATH

	# commit new idea
	git add $DIR/$INPUT_SAFE
	git commit -m "add post idea: $INPUT"

end
