{
  description = "R Flake builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          make-templates = pkgs.writeShellScriptBin "make-templates" ''
            r_file=$(wget -qO- "https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv")
            r_dates_versions=$(echo "$r_file" | tail -n +2 | cut -d',' -f2,4 | tr -d '"' | sort)
            daily_dates=$(git ls-remote https://github.com/rstats-on-nix/nixpkgs/ "????-??-??" --tags | cut -d"/" -f3)

            while IFS= read -r curdatev
            do
               curver=$(echo "$curdatev" | cut -d',' -f1)
               curdate=$(echo "$curdatev" | cut -d',' -f2)
               echo "$curdate"
               mkdir -p "templates/$curdate"
               mkdir -p "templates/$curver"
               cp templates/default/flake.nix "templates/$curdate/flake.nix"
               sed -i  "s|url = \"https://github.com/rstats-on-nix/nixpkgs/archive/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\.tar\.gz\";|url = \"https://github.com/rstats-on-nix/nixpkgs/archive/$curdate.tar.gz\";|" "templates/$curdate/flake.nix"
               cp "templates/$curdate/flake.nix" "templates/$curver/flake.nix"
            done < <(printf '%s\n' "$r_dates_versions")

            while IFS= read -r curdate
            do
               echo "$curdate"
               mkdir -p "templates/daily-$curdate"
               cp templates/default/flake.nix "templates/daily-$curdate/flake.nix"
               sed -i  "s|url = \"https://github.com/rstats-on-nix/nixpkgs/archive/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\.tar\.gz\";|url = \"https://github.com/rstats-on-nix/nixpkgs/archive/$curdate.tar.gz\";|" "templates/daily-$curdate/flake.nix"
            done < <(printf '%s\n' "$daily_dates")

            temps=$(ls templates)
            echo '{' > templates.nix
            while IFS= read -r curtemp
            do
                curtempname=$(echo $curtemp | sed s/[.]/_/g)
                echo "  r-$curtempname = { path = ./templates/$curtemp; description = "\"$curtemp\""; }; " >> templates.nix
            done < <(printf '%s\n' "$temps")
            echo '}' >> templates.nix
            ${pkgs.nixfmt-rfc-style}/bin/nixfmt templates.nix
          '';
        }
      );
      defaultPackage = forAllSystems (system: self.packages.${system}.make-templates);

      templates = import ./templates.nix;
      defaultTemplate = self.templates.r-default;
    };
}
