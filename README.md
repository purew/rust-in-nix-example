# rust-in-nix-example

A demonstration of proper Rust integration with git submodules in a Nix flake build process.

## What This Project Demonstrates

This project shows how to correctly set up a Rust project with:

- **Git submodules in Nix flakes** - Proto files are stored in a git submodule
- **Protobuf compilation** - Using `prost` and `prost-build` for protobuf parsing
- **Reproducible Rust toolchain** - Using `fenix` to pin the exact Rust version from `rust-toolchain.toml`
- **Proper build caching** - Using `crane` for efficient, incremental Nix builds
- **Comprehensive CI checks** - Clippy, rustfmt, tests, and cargo-deny all run via `nix flake check`

## Key Nix Flake Features

### Git Submodule Support

The critical piece for submodule support is in `flake.nix`:

```nix
inputs = {
  # ... other inputs ...
  self.submodules = true;  # This enables git submodule fetching
};
```

Without this, Nix will not fetch submodules and the build will fail when trying to access files in `proto-fixed/`.

### Source Filtering

The source filter must explicitly include submodule paths:

```nix
src = pkgs.lib.cleanSourceWith {
  src = ./.;
  filter = path: type:
    (pkgs.lib.hasInfix "proto-fixed" path) ||  # Include submodule
    (pkgs.lib.hasSuffix ".proto" path) ||
    (pkgs.lib.hasSuffix "deny.toml" path) ||
    (craneLib.filterCargoSources path type);
};
```

### Rust Toolchain via Fenix

The Rust toolchain is pinned using `rust-toolchain.toml` and loaded via fenix:

```nix
rustToolchain = fenixPkgs.fromToolchainFile {
  file = ./rust-toolchain.toml;
  sha256 = "sha256-...";
};

craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
```

This ensures the same Rust version (including clippy, rustfmt, rust-analyzer) is used everywhere.

## Checks

Running `nix flake check` executes:

| Check | Description |
|-------|-------------|
| `rust-in-nix-example` | Main build |
| `rust-in-nix-example-tests` | Unit tests via `cargo test` |
| `rust-in-nix-example-clippy` | Linting with `--deny warnings` |
| `rust-in-nix-example-fmt` | Format check via `rustfmt` |
| `rust-in-nix-example-deny` | Dependency auditing via `cargo-deny` |

## Usage

### Build

```sh
nix build
```

### Run

```sh
nix run
```

### Development Shell

```sh
nix develop
```

This provides a shell with:
- Rust toolchain (as specified in `rust-toolchain.toml`)
- protobuf compiler
- cargo-deny

### Run All Checks

```sh
nix flake check
```

## Project Structure

```
.
├── flake.nix           # Nix flake configuration
├── flake.lock          # Pinned flake inputs
├── Cargo.toml          # Rust package manifest
├── Cargo.lock          # Pinned Rust dependencies
├── rust-toolchain.toml # Rust version specification
├── deny.toml           # cargo-deny configuration
├── build.rs            # Proto compilation build script
├── src/
│   └── main.rs         # Application entry point
└── proto-fixed/        # Git submodule containing .proto files
    └── proto/
        └── person.proto
```

## Supported Platforms

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`
