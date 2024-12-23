{
  description = "My Bitcoin Core Cirrus CI runner infrastructure as a NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    bitcoin-core-cirrus-runner = {
      url = "github:0xB10C/bitcoin-core-cirrus-runner?ref=2024-12-38c3-ctf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      bitcoin-core-cirrus-runner,
      disko,
    }:
    let
      # admin user:
      # FIXME: If you fork this repository, you'll want to change these.
      username = "b10c";
      sshPubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtQmhXAp3F/KcaK3NzA30b2jE26zdYg6msXTXMBVJvZ8p8adHVYrl1QVFieeIjZvy1sj0gMXPOjYpgOm7OdwiZL4h0B9/FU49h+TLly6+YBwO/XYDR84WCvtv1/HVrVSIcYdMZo2+5fnGV3zxrtC/ndBheu17PbW7pvB+O7ODjxJa2tu66Q0If1cYH85PNkF3/jzsjQRwzo88eMxPEqVfp3MfYxJR53oWlXN2SUe1F/6FkeUulx9FpHgmWtPVLsGLd285GeQwsBUIRl+VnJQwCSB69YWgATR0zlRloFcfu1DhOCo5rGXnOvGmOWZ9LYpybwvuotQ8AGbsdNpZWYhQUNGF/YealVkyKABKhIHRQcGkqqqSGHpx6ui1tLkBHJWFgdCTU6eaK9OhgnjyHDJDtPGDl/Ek84JGYHp8+seHvE0/4GvQ2hQXUEUSQpxNwlwT1TKJ8uEMQuSn5zOK9TBSrYktW9h7HRe0ZQd23C6J38Lhxt9bJ3FcyfxFqogJZz3szAo0iR/bsjyeErfjKqeDHDZu4x9OISntrL42tCtNnb9ucWHo2nd+y+2X/hGQlGDdCo+RFi4cZeIHusibmr6J8FHnYgtNldamU2MYKk9R26MmPwVD/eM1Eq/sKL1jhAH3vfnxSifsQ6DvMicRiXWy/AOb3ZdZWVCLSd0mmrjkncQ==";

      mkHost =
        {
          name,
          arch,
          disk-config,
          hardware-config,
          config,
        }:
        nixpkgs.lib.nixosSystem {
          system = arch;
          modules = [
            disko.nixosModules.disko
            bitcoin-core-cirrus-runner.nixosModules.default
            disk-config
            hardware-config
            (import ./base.nix {
              lib = nixpkgs.lib;
              inherit username sshPubKey;
            })
            config
            { networking.hostName = name; }
          ];
        };
    in
    {
      nixosConfigurations = {

        # Big host with 32 physical cores (64 threads) and 256 GB of RAM and
        # a single, non-nvme disk
        ci-big = mkHost {
          name = "ci-big";
          arch = "x86_64-linux";
          disk-config = ./disko-configs/single-disk.nix;
          hardware-config = ./hardware-configs/big.nix;
          config = {
            services.cirrus-ephemeral-vm-runner = {
              enable = true;
              name = "big";
              vms = {
                small = {
                  count = 6;
                  cpu = 4;
                  memory = 8;
                };
                medium = {
                  count = 4;
                  cpu = 8;
                  memory = 16;
                };
              };
            };
          };
        };

        # a test host with 8 physical cores and 64 GB of RAM and two NVMEs
        ci-test = mkHost {
          name = "ci-test";
          arch = "x86_64-linux";
          disk-config = ./disko-configs/dual-nvme.nix;
          hardware-config = ./hardware-configs/test.nix;
          config = {
            services.cirrus-ephemeral-vm-runner = {
              enable = true;
              name = "test";
              vms = {
                small = {
                  count = 16;
                  cpu = 1;
                  memory = 3;
                };
              };
            };
          };
        };

      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
