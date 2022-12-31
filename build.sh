#!/bin/bash
GPG_KEY="71C9AF96CD2F3A8A837EFFBB015D4A9B1D4A2370"
OUTPUT_DIR="publish"

script_full_path=$(dirname "$0")
cd "$script_full_path" || exit 1
rm $OUTPUT_DIR/Packages* $OUTPUT_DIR/*Release*
mkdir -p $OUTPUT_DIR

echo "[Repository] Generating Packages..."
apt-ftparchive packages ./pool > $OUTPUT_DIR/Packages
zstd -q -c19 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.zst
xz -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.xz
bzip2 -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.bz2
gzip -nc9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.gz
lzma -c9 $OUTPUT_DIR/Packages > $OUTPUT_DIR/Packages.lzma

echo "[Repository] Generating Release..."
apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="ElleKit (unofficial)" \
        -o APT::FTPArchive::Release::Label="Unofficial ElleKit builds" \
        -o APT::FTPArchive::Release::Suite="stable" \
        -o APT::FTPArchive::Release::Version="1.0" \
        -o APT::FTPArchive::Release::Codename="ellekit-dhinakg" \
        -o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64" \
        -o APT::FTPArchive::Release::Components="main" \
        -o APT::FTPArchive::Release::Description="Unofficial nightly ElleKit builds from dhinakg. These are as close to stock as possible, but are not guaranteed to be supported by the developer." \
        release $OUTPUT_DIR > $OUTPUT_DIR/Release

echo "[Repository] Signing Release using GPG Key..."
if ! gpg -vabs -u $GPG_KEY -o $OUTPUT_DIR/Release.gpg $OUTPUT_DIR/Release; then
        echo "[Repository] Generated detached signature for Release"
else
        echo "Detached signature signing failed."
fi

if ! gpg --clearsign -u $GPG_KEY -o $OUTPUT_DIR/InRelease $OUTPUT_DIR/Release; then
        echo "[Repository] Generated in-line signature for Release"
else
        echo "In-line signature signing failed."
fi

mv pool "$OUTPUT_DIR"
