function fk

    if ! test -n $argv[1]
        echo exiting
        return
    else
        flatpak kill $(flatpak list | cut -d \t -f 2 | grep -i $argv[1] | head -n 1)
    end
end
