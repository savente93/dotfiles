function gcb
	if test -n $argv[2]
		git checkout -b $argv[1] main
	else
		# in case user provided more arguments than just branch name
		git checkout -b $argv[1] main $argv[2..-1]
	end
end
