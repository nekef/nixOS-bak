{ config, pkgs, ... }:

let
  nix-helper = pkgs.writeShellScriptBin "nix-helper" ''
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'

    show_menu() {
        echo -e "''${BLUE}======================================"
        echo -e "      NixOS Interactive Helper"
        echo -e "======================================"
        echo -e "''${NC}1) Edit configuration.nix"
        echo -e "2) Apply changes (Rebuild Switch)"
        echo -e "3) Update channels & Upgrade system"
        echo -e "4) List system generations"
        echo -e "5) Clean garbage (keep last 7 days)"
        echo -e "6) Deep clean (delete all old generations)"
        echo -e "7) Optimize Nix store (hardlink duplicates)"
        echo -e "8) Total Bootloader Clean (Wipe entries)"
        echo -e "q) Quit"
        echo -e "''${BLUE}--------------------------------------''${NC}"
    }

    while true; do
        show_menu
        read -p "Choose an option: " choice
        case $choice in
            1) sudo nano /etc/nixos/configuration.nix ;;
            2) echo -e "''${GREEN}Applying configuration...''${NC}"; sudo nixos-rebuild switch ;;
            3) echo -e "''${GREEN}Updating channels and upgrading...''${NC}"; sudo nix-channel --update && sudo nixos-rebuild switch --upgrade ;;
            4) echo -e "''${BLUE}System Generations:''${NC}"; sudo nix-env --list-generations --profile /nix/var/nix/profiles/system ;;
            5) echo -e "''${RED}Cleaning garbage older than 7 days...''${NC}"; sudo nix-collect-garbage --delete-older-than 7d ;;
            6) echo -e "''${RED}Deep cleaning all generations...''${NC}"; sudo nix-collect-garbage -d ;;
            7) echo -e "''${GREEN}Optimizing Nix store...''${NC}"; nix-store --optimize ;;
            8) 
                echo -e "''${RED}Wiping old generations and refreshing bootloader...''${NC}"
                sudo nix-collect-garbage -d
                echo -e "''${BLUE}Current Generations:''${NC}"
                sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
                sudo /run/current-system/bin/switch-to-configuration boot
                echo -e "''${GREEN}Bootloader menu synced.''${NC}"
                ;;
            q) echo "Goodbye!"; exit 0 ;;
            *) echo -e "''${RED}Invalid option.''${NC}" ;;
        esac
        echo -e "\nPress Enter to return to menu..."
        read
        clear
    done
  '';
in
{
  imports = [ 
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # Bootloader & Kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 5; 
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Firewall & SSH
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.enable = false;

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User & Shell
  users.users.nekef = {
    isNormalUser = true;
    description = "nekef chk";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh; 
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      weather = "curl -s 'wttr.in/Nobleford,Alberta?m'";
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    jetbrains-mono
    noto-fonts-color-emoji
  ];

  # HOME MANAGER GLOBAL SETTINGS
  home-manager.backupFileExtension = "backup";

  # HOME MANAGER USER SETTINGS
  home-manager.users.nekef = { pkgs, ... }: {
    home.stateVersion = "25.11";
    home.enableNixpkgsReleaseCheck = false;

    # BTOP RICE
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_mocha";
        theme_background = false; 
        vim_keys = true;
      };
    };

    # CAVA RICE
    programs.cava = {
      enable = true;
      settings.color = {
        gradient = 1;
        gradient_count = 8;
        gradient_color_1 = "'#89b4fa'";
        gradient_color_2 = "'#94e2d5'";
        gradient_color_3 = "'#a6e3a1'";
        gradient_color_4 = "'#f9e2af'";
        gradient_color_5 = "'#fab387'";
        gradient_color_6 = "'#eba0ac'";
        gradient_color_7 = "'#f5c2e7'";
        gradient_color_8 = "'#cba6f7'";
      };
    };

    # ZSH RICE
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
        plugins = [ "git" "sudo" ];
      };
    };
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    linuxHeaders
    vim
    wget
    curl
    git
    fastfetch
    hyfetch
    nix-helper
    discord
    vlc
    btop
    cava
    firefox 
    kdePackages.konsole
    pipes-rs
    cbonsai
    cmatrix
    tenki
  ];

  system.stateVersion = "25.11"; 
}
