function mcp
    if ! path is $argv[-1] -d;
	mkdir $argv[-1]
    end
    cp $argv[1..]
end
