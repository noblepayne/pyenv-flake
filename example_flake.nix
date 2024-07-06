{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.pyenv.url = "github:noblepayne/pyenv-flake";
  inputs.pyenv.inputs.nixpkgs.follows = "nixpkgs";
  outputs = {
    self,
    nixpkgs,
    pyenv,
    ...
  }: let
    supportedSystems = ["x86_64-linux"];
    forAllSystems = fn:
      nixpkgs.lib.mapAttrs
      fn
      (nixpkgs.lib.getAttrs supportedSystems nixpkgs.legacyPackages);
  in {
    formatter = forAllSystems (system: pkgs: pkgs.alejandra);
    packages = forAllSystems (system: pkgs: {
      python2 = pkgs.callPackage "${pyenv}/python.nix" {
        version = "2";
        hash = "sha256-eLbT6ONQ4fJFwQsLIINiTcgpJTY2ciDdpb5df0up2pU=";
        # extraBuildInputs = [pkgs.postgresql];
      };
      python3 = pkgs.callPackage "${pyenv}/python.nix" {
        version = "3";
        hash = "sha256-Wdarrti8t0GGRPP/rVlV7AeRqzfV7b9yeQXKjidiQBk=";
        # extraBuildInputs = [pkgs.postgresql];
      };
      pyenv = pkgs.callPackage "${pyenv}/pyenv.nix" {
        global = "3";
        pythons = with self.packages.${system}; [python2 python3];
      };
      default = self.packages.${system}.pyenv;
    });
    devShells = forAllSystems (system: pkgs: {
      default = pkgs.mkShell {
        name = "pyenvShell";
        buildInputs = self.packages.${system}.python2.buildInputs ++ [pkgs.postgresql];
        packages = [self.packages.${system}.pyenv];
        shellHook = ''
          eval "$(pyenv init -)"
          # now try e.g. pip install --user psycopg2
        '';
      };
    });
  };
}
