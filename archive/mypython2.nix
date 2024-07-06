# WIP derivation for pyenv-built python? TBD...
{
  stdenv,
  lib,
  pyenv,
  readline,
  zlib,
  pkg-config,
  curl,
  cacert,
  bzip2,
  openssl,
  libffi,
  ncurses,
  sqlite,
  writeShellScriptBin,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  name = "mypython2";
  src = ./.;
  fakeCurl = writeShellScriptBin "curl" ''
    ${curl}/bin/curl -v $@
    exit 1
  '';
  fakeCurl2 = writeShellScriptBin "curl" ''
    exit 0
  '';
  pythonSources = stdenv.mkDerivation {
    name = "pyenv-python-source";
    nativeBuildInputs = [cacert pyenv];
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-eLbT6ONQ4fJFwQsLIINiTcgpJTY2ciDdpb5df0up2pU=";
    buildCommand = ''
      export HOME=$(mktemp -d)
      export PATH="${finalAttrs.fakeCurl}/bin:$PATH"
      pyenv install -k 2.7.18 || true
      mkdir $out
      cp -rT $HOME/.pyenv $out
    '';
  };
  nativeBuildInputs = [pyenv cacert pkg-config];
  buildInputs = [zlib readline openssl bzip2 sqlite ncurses finalAttrs.fakeCurl2];
  buildPhase = let
    makeCompilerPaths = flag: folder: output: pkgList: let
      searchPaths = map (pkg: "${flag}${lib.makeSearchPathOutput output folder [pkg]}") pkgList;
    in (lib.strings.concatStringsSep " " searchPaths);
    LDFLAGS = makeCompilerPaths "-L" "lib" "" finalAttrs.buildInputs;
    CPPFLAGS = makeCompilerPaths "-I" "include" "dev" finalAttrs.buildInputs;
  in ''
    export HOME=$(mktemp -d)
    export LDFLAGS="${LDFLAGS}"
    export CPPFLAGS="${CPPFLAGS}"
    mkdir $HOME/.pyenv
    cp -r ${finalAttrs.pythonSources}/sources $HOME/.pyenv
    chmod -R a+rwx $HOME/.pyenv
    pyenv install -k 2.7.18
    mkdir $out
    rm -r $HOME/.pyenv/sources
    cp -rT $HOME/.pyenv $out
  '';
  # TODO: how to handle PYENV_ROOT? Embrace pyenv at runtime? OR handle .so and use more nix...
  dontFixup = true;
})
