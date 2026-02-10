#!/bin/sh
set -e

REPO="onedotnet/charb-releases"
BINARY="charb"
INSTALL_DIR="${CHARB_INSTALL_DIR:-/usr/local/bin}"

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

# Handle Windows (Git Bash, WSL, or Cygwin)
# On Windows with Git Bash, OS might be MINGW*, MSYS*, or CYGWIN*
case "$OS" in
  MINGW*|MSYS*|CYGWIN*)
    PLATFORM="windows"
    BINARY="${BINARY}.exe"
    # For Windows x64, we use the x64 binary
    ARCH="x64"
    ;;
  Linux)  PLATFORM="linux" ;;
  Darwin) PLATFORM="darwin" ;;
  *)      echo "Error: Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64)  ARCH="x64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)             echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac

ARTIFACT="${BINARY}-${PLATFORM}-${ARCH}"

# Get latest release download URL
echo "Fetching latest release..."
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ARTIFACT}"

# Create temp directory
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Download
echo "Downloading ${ARTIFACT}..."
if command -v curl >/dev/null 2>&1; then
  curl -fSL --progress-bar "$DOWNLOAD_URL" -o "${TMP_DIR}/${BINARY}"
elif command -v wget >/dev/null 2>&1; then
  wget -q --show-progress "$DOWNLOAD_URL" -O "${TMP_DIR}/${BINARY}"
else
  echo "Error: curl or wget is required"
  exit 1
fi

# On Windows, the .exe file is already executable
# On Unix-like systems, make it executable
case "$OS" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) chmod +x "${TMP_DIR}/${BINARY}" ;;
esac

# Install
if [ -w "$INSTALL_DIR" ]; then
  mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
else
  echo "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
fi

echo ""
echo "charb installed to ${INSTALL_DIR}/${BINARY}"
echo ""
echo "Next steps:"
echo "  charb login"
echo "  charb run claude   # or codex, gemini"
echo "  charb --help"
