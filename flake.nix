{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      haskellNix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          inherit (haskellNix) config;
          overlays = [ haskellNix.overlay ];
        };
        project = pkgs.haskell-nix.cabalProject' {
          src = ./.;
          compiler-nix-name = "ghc9122";
          shell = {
            tools = {
              cabal = "latest";
              haskell-language-server = "latest";
              fourmolu = "latest";
              hlint = "latest";
            };
            buildInputs = with pkgs; [
              just
              nodejs_20
            ];
            shellHook = ''
              export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
              export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            '';
          };
        };
        flake = project.flake { };
        imageTag = self.dirtyShortRev or self.shortRev or "unknown";
        exe = flake.packages."datastar-examples:exe:datastar-examples";
      in
      flake
      // {
        packages.default = exe;
        packages.docker-image = pkgs.dockerTools.buildImage {
          name = "ghcr.io/lambdasistemi/datastar-examples";
          tag = imageTag;
          config = {
            Cmd = [ "${exe}/bin/datastar-examples" ];
            Env = [
              "PORT=3000"
            ];
            ExposedPorts = {
              "3000/tcp" = { };
            };
          };
        };
        inherit imageTag;
        playwrightBrowsers = pkgs.playwright-driver.browsers;
      }
    );

  nixConfig = {
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };
}
