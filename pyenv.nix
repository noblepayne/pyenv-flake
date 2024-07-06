{
  stdenv,
  lib,
  callPackage,
  makeWrapper,
  writeShellScriptBin,
  # pyenv
  gnused,
  gawk,
  pyenv,
  # custom args
  global ? "3",
  pythons ? [{"version" = "3";}],
  ...
}: let
  allPythonPaths = lib.concatStringsSep " " pythons;
  combinedPythons = stdenv.mkDerivation {
    name = "pyenv-pythons";
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      export PATH="${pyenv}/bin:$PATH"
      export PYENV_ROOT=$out
      mkdir -p $out
      for py in ${allPythonPaths}; do
        cp -rT $py/versions $out/versions
        chmod -R +rwx $out
      done
      eval "$(pyenv init -)"
      pyenv global ${global}
      pyenv rehash
    '';
    dontFixup = true; # already done at individual python level
  };
  patchedPyenv = pyenv.overrideAttrs (finalAttrs: prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [makeWrapper];
    postFixup = ''
      wrapProgram $out/bin/pyenv \
        --set PYENV_ROOT "${combinedPythons}" \
    '';
    # --suffix PATH ":" "${lib.makeBinPath [gnused gawk]}" TODO: not sufficient, see below
  });
in
  writeShellScriptBin "pyenv" ''
    ARGS=$@  # capture these for use in subshells
    # Identiy when `pyenv init -` is called and patch request and output.
    if [ "$1" = "init" ] && [ "$2" = "-" ] ; then
      if [ -z "$(echo "$ARGS" | grep -- "--no-rehash")" ]; then
        echo "echo ADDING REHASH $ARGS"
        # add --no-rehash since our shims are frozen
        ${patchedPyenv}/bin/pyenv $ARGS --no-rehash
      else
        ${patchedPyenv}/bin/pyenv $ARGS
      fi
      # Add this patched pyenv to path.
      binPath=$(dirname $(realpath $0))
      if [ -z "$(echo $PATH | grep "$binPath")" ]; then
        echo "echo NOT IN PATH"
        echo "export PATH=\"$binPath:\$PATH\""
      fi
      # Most systems have these already in path, but for minimal environments (.e.g nixos/nix docker image)
      # we need to inject them for pyenv's subscripts to work.
      depsBinPath="${lib.makeBinPath [gnused gawk]}"
      if [ -z "$(echo $PATH | grep "$depsBinPath")" ]; then
        echo "echo SED NOT IN PATH"
        echo "export PATH=\"$depsBinPath:\$PATH\""
      fi
    else
      ${patchedPyenv}/bin/pyenv $ARGS
    fi
  ''
