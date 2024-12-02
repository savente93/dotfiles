function gci
	if test -z $argv[1]
		# if no extra argument open up last commit message in editor
		git commit -e -F $(git rev-parse --git-dir)/COMMIT_EDITMSG
	else
		# else pass all other commands to git to function as usual
		git commit $argv
	end
end
