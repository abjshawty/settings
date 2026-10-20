pacman -Syu
pacman -S --needed git base-devel
mkdir -p ~/Projects
git clone https://aur.archlinux.org/yay.git ~/Projects/yay
cd ~/Projects/yay
makepkg -si
