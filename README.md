# FumoNix
My ultimate NixOS config
```
git clone https://github.com/fumoctl/FumoNix.git
cd FumoNix
sudo nix run 'github:nix-community/disko/latest' -- --mode destroy,format,mount --flake .#fumonix
sudo nixos-install --flake .#fumonix --impure
sudo nixos-enter --root /mnt -c 'passwd fumoctl'
```