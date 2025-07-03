{
  description = "QMK configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      forAllSystems' = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
      forAllSystems =
        fn: forAllSystems' (system: fn system (import nixpkgs { inherit system; }));
    in
    {
      lib = import ./lib.nix inputs;

      nixosModules.default =
        { pkgs, ... }:
        {
          nixpkgs.overlays = self.overlays;
          hardware.keyboard.qmk.enable = true;
          environment.systemPackages = [ pkgs.qmk-flash ];
        };

      overlays = [ (final: prev: { qmk-flash = self.packages.${final.system}.qmk-flash; }) ];

      apps = forAllSystems (
        system: pkgs: {
          qmk-flash = {
            type = "app";
            program = pkgs.lib.getExe self.packages.${system}.qmk-flash;
          };
        }
      );

      packages = forAllSystems (
        _: pkgs: rec {
          qmk-patched = pkgs.qmk.overrideAttrs (oldAttrs: {
            propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ pkgs.python3.pkgs.appdirs ];
          });
          qmk-flash = import ./qmk-flash.nix { inherit pkgs qmk-patched; };
        }
      );
    };
}
