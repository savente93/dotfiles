function fkill

    if ! test -n $argv[1]
        echo exiting
        return
    else
        flatpak kill $(flatpak list | cut -d \t -f 2 | grep $argv[1] | head -n 1)
    end
end
