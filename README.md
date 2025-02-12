# Usage

```
nix flake init --template github:dwinkler1/rix-flakes#r-4_4_2
```

You can generate a `default.nix` using [rix](https://github.com/ropensci/rix) and modify it in-place with the following script:

```
#! /bin/sh

sed -i '1s/^/pkgs:\n/;/^\s*pkgs = import (fetchTarball/d;s/^\s*pkgs.mkShell//' default.nix
```
