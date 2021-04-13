# provides a rustPlatform from a given channel (provided by nixpkgs-mozilla)

{ sources ? import ./nix/sources.nix,
  nixpkgs-mozilla ? import sources.nixpkgs-mozilla,
  channel ? "nightly",
  date ? "2021-03-25",
  targets ? [],
  extensions ? [
    "clippy-preview"
    "rustfmt-preview"
    "rust-src"
    "rust-std"
  ]
}:

self: super:
let
  moz = nixpkgs-mozilla self super;
  rust' = moz.rustChannelOf {
    inherit channel date targets extensions;
  };
  rustc = rust'.rust // { src = "${rust'.rust-src}/lib/rustlib/src/rust"; };
  cargo = rust'.cargo;
  rustLibSrc = super.stdenv.mkDerivation {
    name = "rust-lib-src";
    src = rustc.src;
    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mv library $out 
    '';  
  };
  rustPlatform = super.makeRustPlatform {
    inherit rustc cargo;
  } // { inherit rustLibSrc; };
  rust-analyzer-unwrapped = super.rust-analyzer-unwrapped.override  rec {
    rev = "2021-04-12";
    version = "unstable-${rev}";
    sha256 = "1rg20aswbh9palwr3qfcnscsvzmbmhghn4k0nl11m9j7z6hva6bg";
    cargoSha256 = "1kzpymapkyzlmwy1lwyk3lnpg7y565j1m11z4xc8m4qyh1rdh8vb";
    doCheck = false;
  };
  rust-analyzer = super.rust-analyzer.override { rustcSrc = rustPlatform.rustLibSrc; };
  
  rustracer = rustPlatform.buildRustPackage rec {
    pname = "racer";
    version = "2.1.45";
    src = self.fetchFromGitHub {
      owner = "racer-rust";
      repo = "racer";
      rev = "v${version}";
      sha256 = "1ifni0zd8gn35564sx587xcjmmix33a4dwch515wsiwprxjsbwz8";
    };
    cargoSha256 = "0948dm20qnlndr48fa74i56hscyxp8d4ln2nj2q3migp9y7a44y2";
    nativeBuildInputs = [ self.makeWrapper ];
    buildInputs = self.lib.optional self.stdenv.isDarwin self.darwin.Security;
    RUST_SRC_PATH = rustPlatform.rustcSrc;
    postInstall = ''
      wrapProgram $out/bin/racer --set-default RUST_SRC_PATH ${rustPlatform.rustcSrc}
    '';
    doCheck = false;
  };
in {
  inherit rust' rustc cargo rustPlatform rustracer rust-analyzer-unwrapped rust-analyzer;
}
