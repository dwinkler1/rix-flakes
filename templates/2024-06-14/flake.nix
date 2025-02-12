{
  description = "A Nix-flake-based R development environment";
  inputs = {
    nixpkgs = {
      url = "https://github.com/rstats-on-nix/nixpkgs/archive/2024-06-14.tar.gz";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        usr_settings = import ./default.nix pkgs;
      in
      {
        devShells.default = pkgs.mkShell {
          LOCALE_ARCHIVE =
            usr_settings.LOCALE_ARCHIVE
              or (if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "");
          LANG = usr_settings.LANG or "en_US.UTF-8";
          LC_ALL = usr_settings.LC_ALL or "en_US.UTF-8";
          LC_TIME = usr_settings.LC_TIME or "en_US.UTF-8";
          LC_MONETARY = usr_settings.LC_MONETARY or "en_US.UTF-8";
          LC_PAPER = usr_settings.LC_PAPER or "en_US.UTF-8";
          LC_MEASUREMENT = usr_settings.LC_MEASUREMENT or "en_US.UTF-8";
          packages =
            with pkgs;
            [
              glibcLocales
              nix
            ]
            ++ usr_settings.buildInputs;
          shellHook = usr_settings.shellHook;
        };
      }
    );
}
