#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Analog Devices, Inc.
# ==============================================================================
# install_quartus.sh — Silent installation of Intel Quartus Prime Lite
#
# This script is called by the Dockerfile when QUARTUS_INSTALLER is set.
# It can also be run standalone inside the container to add Quartus later.
#
# Usage:
#   ./install_quartus.sh <path/to/QuartusLiteSetup-*.run> [install_dir]
#
# Download Quartus Prime Lite from:
#   https://www.intel.com/content/www/us/en/software-kit/
#   (search: Quartus Prime Lite Edition for Linux)
#
# Typical installer filename: QuartusLiteSetup-23.1std.0.991-linux.run
# Size: ~4.5 GB  (+ device support files, e.g. Cyclone V: +3 GB)
# ==============================================================================
set -e

INSTALLER="${1:?Usage: $0 <installer.run> [install_dir]}"
INSTALL_DIR="${2:-/opt/quartus}"

if [ ! -f "${INSTALLER}" ]; then
    echo "ERROR: Installer not found: ${INSTALLER}"
    echo ""
    echo "Download from:"
    echo "  https://www.intel.com/content/www/us/en/software-kit/794624/"
    exit 1
fi

echo "Installing Quartus Prime Lite to ${INSTALL_DIR} ..."
echo "Installer: $(basename ${INSTALLER}) ($(du -sh ${INSTALLER} | cut -f1))"
echo ""

chmod +x "${INSTALLER}"

# qinst is Intel's current online installer.  The Makeself wrapper receives
# its own flags first; qinst arguments must follow `--`.
"${INSTALLER}" \
    --accept -- \
    --cli \
    --download-dir /tmp/quartus-download \
    --install-dir "${INSTALL_DIR}" \
    --accept-eula \
    --auto-install \
    --delete-downloads

echo ""
echo "Quartus installed. Adding to PATH..."

# Add to PATH system-wide
QUARTUS_SH="$(find "${INSTALL_DIR}" -type f -path '*/quartus/bin/quartus_sh' -print -quit)"
test -n "${QUARTUS_SH}"
QUARTUS_ROOT="$(dirname "$(dirname "${QUARTUS_SH}")")"
ln -sfn "${QUARTUS_ROOT}" "${INSTALL_DIR}/current"

cat > /etc/profile.d/quartus.sh << EOF
export PATH="${INSTALL_DIR}/current/bin:\${PATH}"
export QUARTUS_ROOTDIR="${INSTALL_DIR}/current"
EOF

chmod +x /etc/profile.d/quartus.sh

echo ""
echo "Verifying installation..."
"${INSTALL_DIR}/current/bin/quartus_sh" --version

echo ""
echo "Done. Useful commands:"
echo "  quartus_sh --flow compile <project.qpf>   — Full compile flow"
echo "  quartus_map --read_settings_files=on <qsf> — Analysis + synthesis"
echo "  quartus_fit  — Place and route"
echo "  quartus_asm  — Generate bitstream"
echo "  quartus_sta  — Timing analysis"
echo "  quartus_pgm  — Program device"
