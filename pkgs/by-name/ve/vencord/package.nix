{ buildNpmPackage
, fetchFromGitHub
, lib
, esbuild
, buildWebExtension ? false
}:
let
  version = "1.8.8";
  gitHash = "a66138f";
in
buildNpmPackage rec {
  pname = "vencord";
  inherit version;

  src = fetchFromGitHub {
    owner = "Vendicated";
    repo = "Vencord";
    rev = "v${version}";
    hash = "sha256-1T5WvD7z/WhU0X2LiuUNtlncKrGyDO5j1oB6VCD7V6w=";
  };

  ESBUILD_BINARY_PATH = lib.getExe (esbuild.overrideAttrs (final: _: {
    version = "0.15.18";
    src = fetchFromGitHub {
      owner = "evanw";
      repo = "esbuild";
      rev = "v${final.version}";
      hash = "sha256-b9R1ML+pgRg9j2yrkQmBulPuLHYLUQvW+WTyR/Cq6zE=";
    };
    vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
  }));

  # Supresses an error about esbuild's version.
  npmRebuildFlags = [ "|| true" ];

  makeCacheWritable = true;
  npmDepsHash = "sha256-QYsiRsWP5LljD4e4FUmlIRutnzr5dIOZ6dqUMEECPcw=";
  npmFlags = [ "--legacy-peer-deps" ];
  npmBuildScript = if buildWebExtension then "buildWeb" else "build";
  npmBuildFlags = [ "--" "--standalone" "--disable-updater" ];

  prePatch = ''
    cp ${./package-lock.json} ./package-lock.json
    chmod +w ./package-lock.json
  '';

  VENCORD_HASH = gitHash;
  VENCORD_REMOTE = "${src.owner}/${src.repo}";

  installPhase =
    if buildWebExtension then ''
      cp -r dist/chromium-unpacked/ $out
    '' else ''
      cp -r dist/ $out
    '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Vencord web extension";
    homepage = "https://github.com/Vendicated/Vencord";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ FlafyDev NotAShelf Scrumplex ];
  };
}
