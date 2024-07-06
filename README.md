# pyenv-flake
An experimental flake that can build pyenv pythons.

## Example: devShell
pyenv-flake's default devShell can be used as an evironment suitable for building pyenv pythons.
```bash
$ nix develop github:noblepayne/pyenv-flake --extra-experimental-features 'nix-command flakes'
[nix shell]$ pyenv install 2.7.18
Downloading Python-2.7.18.tar.xz...
-> https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tar.xz
Installing Python-2.7.18...
patching file configure
[...]
Installed Python-2.7.18 to /home/wes/.pyenv/versions/2.7.18
[nix shell]$ pyenv global 2.7.18
[nix shell]$ python2
Python 2.7.18 (default, Jan  1 1980, 00:00:00) 
[GCC 13.2.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> 
```

## Example: Load flake in shell or bash_profile
```bash
[wes@nixos:~]$ which python
which: no python in (/run/wrappers/bin:/home/wes/.nix-profile/bin:/nix/profile/bin:/home/wes/.local/state/nix/profile/bin:/etc/profiles/per-user/wes/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin)
# Or put in `.bash_profile`
[wes@nixos:~]$ eval "$(nix run github:noblepayne/pyenv-flake/v2 -- init -)"
[wes@nixos:~]$ which python
/nix/store/9qr1j9lnmfvq8v6vqf4cj39h03panmy9-pyenv-pythons/shims/python
[wes@nixos:~]$ pyenv versions
  2.7.18
* 3.12.3 (set by /nix/store/9qr1j9lnmfvq8v6vqf4cj39h03panmy9-pyenv-pythons/version)
[wes@nixos:~]$ python
Python 3.12.3 (main, Jan  1 1980, 00:00:00) [GCC 13.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> 
[wes@nixos:~]$ pyenv shell 2
[wes@nixos:~]$ python
Python 2.7.18 (default, Jan  1 1980, 00:00:00) 
[GCC 13.2.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> 
```

## Example: Declarative:
- TODO: export proper functions?

pyenv-flake can be used to build immutable pyenv installations with a set of pythons available.

See [this example consumer flake](example_flake.nix) or the following repl session.

```nix
Welcome to Nix 2.18.4. Type :? for help.
nix-repl> nixpkgs = builtins.getFlake("github:NixOS/nixpkgs/nixos-24.05")                                 
nix-repl> pkgs = nixpkgs.legacyPackages.x86_64-linux
nix-repl> pyenvf = builtins.getFlake(builtins.getEnv("PWD"))                                              
nix-repl> python2 = pkgs.callPackage "${pyenvf}/python.nix" {version = "2";}                              
nix-repl> python2 = pkgs.callPackage "${pyenvf}/python.nix" {version = "2"; hash = "";}                   
nix-repl> pyenv = pkgs.callPackage "${pyenvf}/pyenv.nix" {global = python2.version; pythons = [python2];}
nix-repl> :b pyenv
# warning: found empty hash, assuming 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
# error: hash mismatch in fixed-output derivation '/nix/store/3vsvbic1q0xhwgjh7acwr7rqn9ji79ri-pyenv-python-source-2.drv':
#          specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
#             got:    sha256-eLbT6ONQ4fJFwQsLIINiTcgpJTY2ciDdpb5df0up2pU=

nix-repl> python2 = pkgs.callPackage "${pyenvf}/python.nix" {version = "2"; hash = "sha256-eLbT6ONQ4fJFwQsLIINiTcgpJTY2ciDdpb5df0up2pU=";}
nix-repl> pyenv = pkgs.callPackage "${pyenvf}/pyenv.nix" {global = python2.version; pythons = [python2];}                                  
nix-repl> :b pyenv
This derivation produced the following outputs:
  out -> /nix/store/hs5as23ggy196zzf4f7rbs6qc6hy0bqq-pyenv
```
```bash
$ /nix/store/hs5as23ggy196zzf4f7rbs6qc6hy0bqq-pyenv/bin/pyenv versions
  system
* 2.7.18 (set by /nix/store/hy7rq2r5fkii0jam71n0dw040wyjcvx9-pyenv-pythons/version)
$ /nix/store/hs5as23ggy196zzf4f7rbs6qc6hy0bqq-pyenv/bin/pyenv exec python
Python 2.7.18 (default, Jan  1 1980, 00:00:00) 
[GCC 13.2.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> 
```