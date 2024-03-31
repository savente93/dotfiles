
# create new branch from main instead of current one
function gcb
	if test set -q $argv[2] 
		git checkout -b $1 main
	else
		# in case user provided more arguments than just branch name
		git checkout -b $1 main $argv[2..-1]
	end
end



