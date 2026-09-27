#!/usr/bin/env bash
set -eu

if (( $# != 1 )); then printf 'Usage: %s PREFIX\n' "$0" >&2; exit 2; fi
prefix="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$script_dir/bash-3.2-patches.sha256"
work="$(mktemp -d "${TMPDIR:-/tmp}/uniopt-bash32-build.XXXXXX")"
archive="$work/bash-3.2.tar.gz"
trap 'rm -rf "$work"' EXIT

curl -fsSLo "$archive" https://ftp.gnu.org/gnu/bash/bash-3.2.tar.gz
printf '%s  %s\n' '26c99025b59e30779300b68adb764f824974d267a4d7cc1b347d14a2393f9fb4' "$archive" | sha256sum -c -
tar -xzf "$archive" -C "$work"

i=1
while (( i <= 57 )); do
  patch_name="$(printf 'bash32-%03d' "$i")"
  curl -fsSLo "$work/$patch_name" "https://ftp.gnu.org/gnu/bash/bash-3.2-patches/$patch_name"
  expected="$(awk -v name="$patch_name" '$2 == name { print $1 }' "$manifest")"
  [[ -n "$expected" ]] || { printf 'Missing checksum for %s\n' "$patch_name" >&2; exit 1; }
  printf '%s  %s\n' "$expected" "$work/$patch_name" | sha256sum -c -
  (cd "$work/bash-3.2" && patch -p0 <"$work/$patch_name")
  i=$((i + 1))
done

(cd "$work/bash-3.2" && ./configure --prefix="$prefix" --without-bash-malloc && make -j2 && make install)
"$prefix/bin/bash" -c '[[ ${BASH_VERSINFO[0]} == 3 && ${BASH_VERSINFO[1]} == 2 && ${BASH_VERSINFO[2]} == 57 ]]'
