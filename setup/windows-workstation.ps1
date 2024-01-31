# Work won't let me have a linux machine. very sadge :(

# install scoop 
iwr -useb get.scoop.sh | iex

scoop install sudo
sudo scoop install 7zip git openssh --global
scoop install curl grep sed less touch clink helix topgrade vivaldi wezterm espanso fzf navi starship docker 

# install pixi
iwr -useb https://pixi.sh/install.ps1 | iex

# pixi completion
Add-Content -Path $PROFILE -Value '(& pixi completion --shell powershell) | Out-String | Invoke-Expression'

# winget installs
winget install 1password spotify discord teams miro qgis

# install wsl
wsl --install ubuntu 2