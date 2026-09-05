#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

PKG="$1"
CACHE="/var/cache/pacman/pkg"

CURRENT=$(pacman -Q "$PKG" 2>/dev/null | awk '{print $2}')

echo "Searching cached versions for: $PKG"
echo

shopt -s nullglob
CANDIDATES=("$CACHE"/"$PKG"-*.pkg.tar.{zst,xz})
shopt -u nullglob

# Keep only exact name matches: pacman files are name-ver-rel-arch.pkg.tar.*
# and ver/rel/arch never contain hyphens, so anything left over after
# stripping "$PKG-" must be exactly three hyphen-free fields.
PKGS=()
for f in "${CANDIDATES[@]}"; do
    REST=$(basename "$f")
    REST="${REST#"$PKG"-}"
    REST="${REST%.pkg.tar.zst}"
    REST="${REST%.pkg.tar.xz}"
    if [[ "$REST" =~ ^[^-]+-[^-]+-[^-]+$ ]]; then
        PKGS+=("$f")
    fi
done

if [ ${#PKGS[@]} -eq 0 ]; then
    echo "No cached versions found for $PKG"
    exit 1
fi

mapfile -t PKGS < <(printf '%s\n' "${PKGS[@]}" | sort -Vr)

echo "Available versions:"
for i in "${!PKGS[@]}"; do
    NAME=$(basename "${PKGS[$i]}")
    MARK=""
    if [ -n "$CURRENT" ] && [[ "$NAME" == "$PKG-$CURRENT-"* ]]; then
        MARK="  <- installed"
    fi
    printf "%d) %s%s\n" "$((i+1))" "$NAME" "$MARK"
done

echo
read -rp "Select version number: " NUM

if ! [[ "$NUM" =~ ^[0-9]+$ ]] || [ "$NUM" -lt 1 ] || [ "$NUM" -gt "${#PKGS[@]}" ]; then
    echo "Invalid selection"
    exit 1
fi

FILE="${PKGS[$((NUM-1))]}"

echo
echo "Installing: $FILE"
sudo pacman -U "$FILE"

echo
if pacman-conf IgnorePkg 2>/dev/null | grep -qx "$PKG"; then
    echo "$PKG is in IgnorePkg, so pacman -Syu will keep this version."
else
    echo "Note: pacman -Syu will upgrade $PKG again."
    echo "To hold this version, add to /etc/pacman.conf under [options]:"
    echo "    IgnorePkg = $PKG"
fi
