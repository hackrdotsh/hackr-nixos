{ stdenv, src }:
src.packages.${stdenv.hostPlatform.system}.default
