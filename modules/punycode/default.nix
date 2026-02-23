{ pkgs }:
let
  inherit (pkgs) lib;
in
pkgs.stdenv.mkDerivation {
  pname = "punyblock";
  version = "0.1.0";
  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: _type: lib.hasSuffix ".c" path;
  };
  dontConfigure = true;
  dontFixup = true; # standalone .so deployed into Docker image
  buildPhase = ''
    $CC -shared -Wall -Werror -fpic -fvisibility=hidden -O2 -o punyblock.so punyblock.c
  '';
  installPhase = ''
    mkdir -p $out/lib
    cp punyblock.so $out/lib/
  '';
}
