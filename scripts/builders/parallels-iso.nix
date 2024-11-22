{ config, pkgs, lib, ... }:
{
 
 # Enable guest additions.
  nixpkgs.config.allowUnfree = true;
  hardware.parallels.enable = true;

  # Resolve conflict for timesyncd service
  services.timesyncd.enable = lib.mkForce true;
}