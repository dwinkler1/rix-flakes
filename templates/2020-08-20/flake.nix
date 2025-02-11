{
  description = "A Nix-flake-based R development environment";
  inputs = {
    nixpkgs = {
      url = "https://github.com/rstats-on-nix/nixpkgs/archive/2020-08-20.tar.gz";
    };
  };
  outputs =
    { self, nixpkgs }:
    let
      installed_r_pkgs =
        p: with p; [
          data_table
          ggplot2
          A3
        ];
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          }
        );

    in
    {
      overlays.default = final: prev: {
        radianEnv = prev.radianWrapper.override {
          packages = installed_r_pkgs prev.rPackages;
        };
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {

            LOCALE_ARCHIVE =
              if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
            LANG = "en_US.UTF-8";
            LC_ALL = "en_US.UTF-8";
            LC_TIME = "en_US.UTF-8";
            LC_MONETARY = "en_US.UTF-8";
            LC_PAPER = "en_US.UTF-8";
            LC_MEASUREMENT = "en_US.UTF-8";
            packages = with pkgs; [
              glibcLocales
              nix
              radianEnv
            ];
            shellHook =
              let
                rtermsys = if pkgs.stdenv.isLinux then "linux" else "mac";
              in
              ''
                mkdir -p .vscode
                tr -d '{}' < .vscode/settings.json > .vscode/tmp.json
                sed -i 's/^ */   /' .vscode/tmp.json
                sed -i '/"r\.rterm/d' .vscode/tmp.json 
                echo '   "r.rterm.${rtermsys}": "${pkgs.radianEnv}/bin/radian",' >> .vscode/tmp.json
                echo '{' > .vscode/settings.json
                cat .vscode/tmp.json | sort -u | sed '/^ *$/d' >> .vscode/settings.json
                echo '}' >> .vscode/settings.json
                rm .vscode/tmp.json
              '';

          };

        }
      );
    };
}
