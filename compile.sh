#!/bin/bash

# Simple tt-flash binary compilation script
# Usage: ./compile.sh

set -e  # Exit on any error

# Color definitions
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

setup_venv() {
    VENV_DIR="venv"

    if [ -d "$VENV_DIR" ]; then
        echo -e "${PURPLE}[INFO] Virtual environment already exists${NC}"
    else
        echo -e "${PURPLE}[INFO] Creating virtual environment...${NC}"
        python3 -m venv "$VENV_DIR"
    fi

    echo -e "${PURPLE}[INFO] Activating virtual environment...${NC}"
    source "$VENV_DIR/bin/activate"

    echo -e "${PURPLE}[INFO] Upgrading pip...${NC}"
    pip install --upgrade pip > /dev/null

    echo -e "${PURPLE}[INFO] Installing project...${NC}"
    pip install -e . > /dev/null
    echo -e "${PURPLE}[INFO] Installing PyInstaller...${NC}"
    pip install pyinstaller > /dev/null
}

clean_build() {
    echo -e "${PURPLE}[INFO] Cleaning previous build artifacts...${NC}"
    rm -rf build/ dist/ *.spec
}

build_binary() {
    echo -e "${PURPLE}[INFO] Building binary with PyInstaller...${NC}"

    PYINSTALLER_CMD="python3 -m PyInstaller"

    # PyInstaller needs a top-level entry script; pointing directly at
    # tt_flash/main.py breaks relative imports inside the package.
    ENTRY_SCRIPT="_entry_point.py"
    echo "from tt_flash.main import main; main()" > "$ENTRY_SCRIPT"

    $PYINSTALLER_CMD \
        --onefile \
        --name tt-flash \
        --collect-all tt_flash \
        --collect-all tt_tools_common \
        --add-data "tt_flash/data/blackhole/fw_defines.yaml:tt_flash/data/blackhole" \
        --add-data "tt_flash/data/wormhole/fw_defines.yaml:tt_flash/data/wormhole" \
        --add-data "tt_flash/data/grayskull/fw_defines.yaml:tt_flash/data/grayskull" \
        --hidden-import importlib_metadata \
        --hidden-import importlib_resources \
        --hidden-import tomli \
        --clean \
        "$ENTRY_SCRIPT"

    rm -f "$ENTRY_SCRIPT"
}

verify_build() {
    if [ -f "dist/tt-flash" ]; then
        echo -e "${GREEN}[INFO] Binary compilation completed successfully${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] Binary creation failed${NC}"
        return 1
    fi
}

rename_binary() {
    echo -e "${PURPLE}[INFO] Renaming binary to tt-flash-${DATE}-${VERSION}${NC}"
    mv dist/tt-flash dist/tt-flash-${DATE}-${VERSION}
    chmod 755 dist/tt-flash-${DATE}-${VERSION}
}

show_completion() {
    echo ""
    echo -e "${PURPLE}[INFO] tt-flash binary is ready for deployment${NC}"
    echo -e "Binary location: ${PWD}/dist/tt-flash-${DATE}-${VERSION}"
    echo -e "Binary size: $(du -sh dist/tt-flash-${DATE}-${VERSION} | cut -f1)"
}

clean_venv() {
    echo -e "${PURPLE}[INFO] Cleaning virtual environment...${NC}"
    rm -rf venv
}

main() {
    VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    DATE=$(date +%Y-%m-%d)

    echo -e "${PURPLE}[INFO] Initiating tt-flash binary compilation...${NC}"
    echo -e "${PURPLE}[INFO] Version: ${VERSION}${NC}"

    setup_venv
    clean_build
    build_binary
    verify_build
    rename_binary
    show_completion
    clean_venv
}

main "$@"
