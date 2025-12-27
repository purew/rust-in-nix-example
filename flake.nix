{
  description = "Rust hello-world with prost protobuf parsing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, fenix, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Use fenix to get Rust 1.90 (nightly) as specified in rust-toolchain.toml
        fenixPkgs = fenix.packages.${system};
        rustToolchain = fenixPkgs.fromToolchainFile {
          file = ./rust-toolchain.toml;
          sha256 = "sha256-SJwZ8g0zF2WrKDVmHrVG3pD2RGoQeo24MEXnNx5FyuI=";
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        # Filter source to only include Rust-relevant files
        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            (pkgs.lib.hasSuffix ".proto" path) ||
            (craneLib.filterCargoSources path type);
        };

        # Common arguments for crane builds
        commonArgs = {
          inherit src;
          strictDeps = true;

          # prost-build needs protobuf compiler
          nativeBuildInputs = [
            pkgs.protobuf
          ];
        };

        # Build just the cargo dependencies for caching
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        # Build the actual crate
        rust-in-nix-example = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });
      in
      {
        checks = {
          inherit rust-in-nix-example;
        };

        packages = {
          default = rust-in-nix-example;
          rust-in-nix-example = rust-in-nix-example;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = rust-in-nix-example;
        };

        devShells.default = craneLib.devShell {
          checks = self.checks.${system};

          packages = [
            pkgs.protobuf
          ];
        };
      });
}
