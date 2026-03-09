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
            };
            buildInputs = with pkgs; [
              just
            ];
          };
        };
        flake = project.flake { };
        imageTag = self.dirtyShortRev or self.shortRev or "unknown";
        exe = flake.packages."todo-datastar-app:exe:todo-datastar-app";
      in
      flake
      // {
        packages.default = exe;
        packages.docker-image = pkgs.dockerTools.buildImage {
          name = "ghcr.io/lambdasistemi/todo-datastar-app";
          tag = imageTag;
          config = {
            Cmd = [ "${exe}/bin/todo-datastar-app" ];
            Env = [
              "PORT=3000"
              "DB_PATH=/data/todos.db"
            ];
            ExposedPorts = {
              "3000/tcp" = { };
            };
            Volumes = {
              "/data" = { };
            };
          };
        };
        inherit imageTag;
      }
    );

  nixConfig = {
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };
}
