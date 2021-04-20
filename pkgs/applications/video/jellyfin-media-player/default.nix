{ lib
, fetchFromGitHub
, fetchzip
, mkDerivation
, stdenv
, Cocoa
, CoreAudio
, CoreFoundation
, MediaPlayer
, SDL2
, cmake
, libGL
, libX11
, libXrandr
, libvdpau
, mpv
, ninja
, pkg-config
, python3
, qtbase
, qtwayland
, qtwebchannel
, qtwebengine
, qtx11extras
}:

mkDerivation rec {
  pname = "jellyfin-media-player";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-media-player";
    rev = "v${version}";
    sha256 = "sha256-500Qlxpqkf+9D/jrzkrYkkFwxs0soLG/I5mgFV1UOc8=";
  };

  jmpDist = fetchzip {
    url = "https://github.com/iwalton3/jellyfin-web-jmp/releases/download/jwc-10.7.2-2/dist.zip";
    sha256 = "sha256-9oxOcSCV1Gm8WLpwVLanyUlhPx5PWUrkkWvKmwND94g=";
  };

  patches = [
    # the webclient-files are not copied in the regular build script. Copy them just like the linux build
    ./fix-osx-resources.patch
    # disable update notifications since the end user can't simply download the release artifacts to update
    ./disable-update-notifications.patch
  ];

  buildInputs = [
    SDL2
    libGL
    libX11
    libXrandr
    libvdpau
    mpv
    qtbase
    qtwebchannel
    qtwebengine
    qtx11extras
  ] ++ lib.optionals stdenv.isLinux [
    qtwayland
  ] ++ lib.optionals stdenv.isDarwin [
    Cocoa
    CoreAudio
    CoreFoundation
    MediaPlayer
  ];

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DQTROOT=${qtbase}"
    "-GNinja"
  ];

  preBuild = ''
    # copy the webclient-files to the expected "dist" directory
    mkdir -p dist
    cp -a ${jmpDist}/* dist
  '';

  postInstall = lib.optionalString stdenv.isDarwin ''
    mkdir -p $out/bin $out/Applications
    mv "$out/Jellyfin Media Player.app" $out/Applications

    # move web-client resources
    mv $out/Resources/* "$out/Applications/Jellyfin Media Player.app/Contents/Resources/"
    rmdir $out/Resources

    # fix 'Could not find the Qt platform plugin "cocoa" in ""' error
    wrapQtApp "$out/Applications/Jellyfin Media Player.app/Contents/MacOS/Jellyfin Media Player"

    ln -s "$out/Applications/Jellyfin Media Player.app/Contents/MacOS/Jellyfin Media Player" $out/bin/jellyfinmediaplayer
  '';

  meta = with lib; {
    homepage = "https://github.com/jellyfin/jellyfin-media-player";
    description = "Jellyfin Desktop Client based on Plex Media Player";
    license = with licenses; [ gpl2Plus mit ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
    maintainers = with maintainers; [ jojosch ];
  };
}
