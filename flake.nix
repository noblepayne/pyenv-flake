{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    supportedSystems = ["x86_64-linux"];
    pkgsBySystem = nixpkgs.lib.getAttrs supportedSystems nixpkgs.legacyPackages;
    forAllSystems = fn: nixpkgs.lib.mapAttrs fn pkgsBySystem;
  in {
    formatter = forAllSystems (system: pkgs: pkgs.alejandra);
    packages = forAllSystems (
      system: pkgs: let
        python3 = pkgs.callPackage ./python.nix {};
        python2 = pkgs.callPackage ./python.nix {
          version = "2";
          hash = "sha256-eLbT6ONQ4fJFwQsLIINiTcgpJTY2ciDdpb5df0up2pU=";
        };
      in {
        inherit python2 python3;
        default = pkgs.callPackage ./pyenv.nix {
          global = "3";
          pythons = [python2 python3];
        };
      }
    );
    devShells = forAllSystems (system: pkgs: {
      default = pkgs.mkShell {
        name = "pyenv-devshell";
        inherit
          (self.packages.${system}.python3)
          LDFLAGS
          CPPFLAGS
          CONFIGURE_OPTS
          ;
        packages = [pkgs.pyenv pkgs.cacert pkgs.curl];
        buildInputs = self.packages.${system}.python3.buildInputs;
        shellHook = ''
          PS1='[nix shell]\$ '
          eval "$(pyenv init -)"
        '';
      };
    });
  };
}
