# pyenv-flake
An experimental nix dev shell that can build pyenv pythons.

## Example
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
