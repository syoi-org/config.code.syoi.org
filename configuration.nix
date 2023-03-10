{ config, pkgs, lib, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ./syoi-code-server.nix
  ];

  # nixos-generate-config doesn't detect mount options automatically
  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Asia/Hong_Kong";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "colemak";

  # Define a admin user account.
  users.users.stommydx = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [ nixpkgs-fmt ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    age
    ansible
    bat
    btop
    cargo
    cmake
    delta
    dig
    exa
    file
    gcc
    gh
    gnumake
    jq
    neofetch
    netcat
    p7zip
    (python3.withPackages (pythonPkgs: with pythonPkgs; [
      ipython
      pandas
    ]))
    rclone
    rustc
    sops
    sshfs
    terraform
    tldr
    tree
    unzip
    wget
    zip
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.domain = "syoi.org";
  networking.firewall.enable = false;
  networking.hostName = "code";
  networking.networkmanager = {
    enable = true;
    connectionConfig = {
      "connection.mdns" = 2;
    };
  };

  programs.command-not-found.enable = false; # use nix-index instead
  programs.java.enable = true;
  programs.git.enable = true;
  programs.iotop.enable = true;
  programs.nix-index.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
  };
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh.enable = true;
    autosuggestions.enable = true;
  };

  # Enable nix-ld
  # For running unpatched binaries such as VS Code remote SSH plugin server
  programs.nix-ld.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  services.resolved = {
    enable = true;
    extraConfig = "MulticastDNS=yes";
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  services.qemuGuest.enable = true;
  services.tailscale.enable = true;

  zramSwap.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
