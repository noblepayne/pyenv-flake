# WIP derivation for pyenv-built python? TBD...
{
  stdenv,
  lib,
  callPackage,
  pyenv,
  readline,
  zlib,
  pkg-config,
  curl,
  cacert,
  bzip2,
  openssl,
  libffi,
  libxcrypt,
  lzma,
  ncurses,
  sqlite,
  writeShellScriptBin,
  autoPatchelfHook,
  # custom args
  version ? "3",
  hash ? "sha256-Wdarrti8t0GGRPP/rVlV7AeRqzfV7b9yeQXKjidiQBk=",
  extraBuildInputs ? [],
  ...
}: let
  # Build linker or compiler flags from list of pkgs.
  # e.g. (makeCompilerFlags {...}) -> "-L/nix/store/123-pkg1/lib -L/nix/store/234-pkg2/lib"
  makeCompilerFlags = {
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
  in (lib.concatStringsSep " " searchPaths);
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "pyenv-python";
    inherit version;
    curlDownloadAndFail = writeShellScriptBin "curl" ''
      ${curl}/bin/curl -v $@
      exit 1
    '';
    curlNoDownloadAndSucceed = writeShellScriptBin "curl" ''
      exit 0
    '';
    pythonSources = stdenv.mkDerivation {
      pname = "pyenv-python-source";
      inherit version;
      nativeBuildInputs = [pyenv cacert finalAttrs.curlDownloadAndFail];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
      buildCommand = ''
        mkdir $out && export PYENV_ROOT="$out"
        pyenv install -k ${finalAttrs.version} || true
      '';
    };
    # Linker flags, e.g. add in .so files of deps
    LDFLAGS = makeCompilerFlags {
      inherit lib;
      output = "";
      folder = "lib";
      flag = "-L";
      pkgList = finalAttrs.buildInputs;
    };
    # Compiler flags, e.g. include additional headers/libs
    CPPFLAGS = makeCompilerFlags {
      inherit lib;
      output = "dev";
      folder = "include";
      flag = "-I";
      pkgList = finalAttrs.buildInputs;
    };
    # Configure option needed for python3 to build _ssl
    CONFIGURE_OPTS = let
      openssls = builtins.filter (pkg: pkg.pname == "openssl") finalAttrs.buildInputs;
      base_openssl = builtins.elemAt openssls 0;
      openssl = base_openssl.dev or base_openssl;
    in "--with-openssl=${openssl}";

    dontUnpack = true;
    dontBuild = true;
    nativeBuildInputs = [pyenv autoPatchelfHook finalAttrs.curlNoDownloadAndSucceed];
    buildInputs = [zlib readline openssl bzip2 sqlite ncurses bzip2 libffi libxcrypt lzma] ++ extraBuildInputs;
    installPhase = ''
      mkdir $out && export PYENV_ROOT="$out"
      # restore previously downloaded sources
      cp -r ${finalAttrs.pythonSources}/sources $out && chmod -R +rwx $out
      # build python
      pyenv install -k ${finalAttrs.version}
      # cleanup
      rm -r $out/sources
    '';
  })
