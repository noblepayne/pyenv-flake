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
    # Build linker or compiler flags from list of pkgs.
    # e.g. (makeCompilerFlags {...}) -> "-L/nix/store/123-pkg1/lib -L/nix/store/234-pkg2/lib"
    makeCompilerFlags = {
      lib, # pkgs.lib
      output, # e.g. "dev" or "" for the default
      folder, # e.g. "lib" or "bin"  or "include"
      flag, # e.g. "-L" or "-I"
      pkgList, # e.g. [pkgs.zlib pkgs.readline]
      ...
    }: let
      # e.g. `-L/nix/store/123-pkg/lib`
      makeSearchPathForPkg = pkg: "${flag}${lib.makeSearchPathOutput output folder [pkg]}";
      # map makeSearchPathForPkg over all pkgs to get list of individual flags
      searchPaths = map makeSearchPathForPkg pkgList;
      # join all flags with spaces
    in (lib.strings.concatStringsSep " " searchPaths);
  in {
    formatter = forAllSystems (system: pkgs: pkgs.alejandra);
    devShells = forAllSystems (system: pkgs: let
      # Libraries needed to build python and deps
      buildInputs = [
        # python
        pkgs.bzip2
        pkgs.libffi
        pkgs.libxcrypt
        pkgs.lzma
        pkgs.ncurses
        pkgs.openssl
        pkgs.readline
        pkgs.sqlite
        pkgs.zlib
        # pip deps
        # pkgs.postgresql # e.g. psycopg2
      ];
    in {
      default = pkgs.mkShell {
        name = "pyenv-devshell";
        inherit buildInputs;
        # Linker flags, e.g. add in .so files of deps
        LDFLAGS = makeCompilerFlags {
          lib = pkgs.lib;
          output = "";
          folder = "lib";
          flag = "-L";
          pkgList = buildInputs;
        };
        # Compiler flags, e.g. include additional headers/libs
        CPPFLAGS = makeCompilerFlags {
          lib = pkgs.lib;
          output = "dev";
          folder = "include";
          flag = "-I";
          pkgList = buildInputs;
        };
        # Configure option needed for python3 to build _ssl
        CONFIGURE_OPTS = "--with-openssl=${pkgs.openssl.dev}";
        # Runtime packages for installing python via pyenv
        packages = [pkgs.pyenv pkgs.curl pkgs.cacert];
        # Setup pyenv
        shellHook = ''
          PS1='[nix shell]\$ '
          eval "$(pyenv init -)"
        '';
      };
    });
  };
}
