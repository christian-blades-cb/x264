{ sources ? import ./nix/sources.nix }:

let
  rust-src-overlay = import "${sources.nixpkgs-mozilla}/rust-src-overlay.nix";
  rust-overlay = import ./rust-overlay.nix { };
  pkgs = import sources.nixpkgs { overlays = [ rust-overlay rust-src-overlay ]; };
  # nj-cli = pkgs.callPackage ./nj-cli.nix { };
  libclang = pkgs.llvmPackages.libclang.lib;
in pkgs.mkShell {
  propagatedBuildInputs= [ pkgs.clang ];
  nativeBuildInputs = [
    pkgs.pkg-config
  ];
  buildInputs = with pkgs; [
    rust-analyzer
    python27
    rustc
    cargo
    rustfmt
    nodejs-12_x
    cacert
    rustracer
    # nj-cli
    cargo-edit
    x264
    # llvmPackages.libclang
    libclang
    clang
    # llvm
  ];

  LIBCLANG_PATH="${libclang}/lib";
}
