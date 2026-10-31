{
  lib,
  stdenvNoCC,
  esbuild,
  makeWrapper,
  nodejs_22,
  nix,
  zstd,
  src,
}:
stdenvNoCC.mkDerivation {
  pname = "snowstead";
  version = "0-unstable-${src.shortRev}";
  inherit src;

  nativeBuildInputs = [
    esbuild
    makeWrapper
    nodejs_22
  ];
  dontConfigure = true;

  # The CLI only needs Node builtins and its in-tree cache-domain package.
  buildPhase = ''
    runHook preBuild
    esbuild apps/cli/src/*.ts --bundle --platform=node --format=esm --target=node22 \
      --alias:@snowstead/cache-domain=./packages/cache-domain/src/index.ts \
      --outdir=apps/cli/dist
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    node --test apps/cli/test/*.test.mjs
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 apps/cli/dist/main.js $out/lib/snowstead/main.mjs
    makeWrapper ${nodejs_22}/bin/node $out/bin/snowstead \
      --add-flags "$out/lib/snowstead/main.mjs" \
      --prefix PATH : ${
        lib.makeBinPath [
          nix
          zstd
        ]
      }
    runHook postInstall
  '';

  meta.mainProgram = "snowstead";
}
