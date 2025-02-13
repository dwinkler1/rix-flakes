#! /bin/sh

sed -i '1s/^/pkgs:\n/;/^\s*pkgs = import (fetchTarball/d;s/^\s*pkgs.mkShell//' default.nix
