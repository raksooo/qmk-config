{ pkgs, qmk-patched, ... }:

let
  nix = pkgs.lib.getExe pkgs.nix;
  qmk = pkgs.lib.getExe qmk-patched;
  jq = pkgs.lib.getExe pkgs.jq;
in
pkgs.writeShellScriptBin "qmk-flash" ''
  set -eu

  if [ $# -ne 1 ]; then
    echo "Usage: $0 <flake-path>#<config-name>"
    exit 1
  fi

  flake=$(echo "$1" | awk -F "#" '{print $1FS"qmkConfigurations."$2}')

  tmpdir=$(mktemp -d)
  jsonfile="$tmpdir/config.json"

  json=$(${nix} eval --raw "$flake")

  echo "$json" | ${jq} ".qmkJson" > "$jsonfile"

  fork=$(echo "$json" | ${jq} -r .fork)
  branch=$(echo "$json" | ${jq} -r .branch)
  keyboard=$(${jq} -r .keyboard "$jsonfile")
  keymap=$(${jq} -r .keymap "$jsonfile")

  export QMK_HOME="/tmp/qmk-flash-qmk_home"
  ${qmk} setup --branch "$branch" --home "$QMK_HOME" --yes "$fork"
  (cd $QMK_HOME; git restore --staged .; git restore .; git clean -fd)

  echo "" >> "$QMK_HOME/keyboards/$keyboard/rules.mk"
  echo "$json" | ${jq} -r .extraRules >> "$QMK_HOME/keyboards/$keyboard/rules.mk"

  echo "" >> "$QMK_HOME/keyboards/$keyboard/config.h"
  echo "$json" | ${jq} -r .extraHeader >> "$QMK_HOME/keyboards/$keyboard/config.h"

  ${qmk} json2c "$jsonfile"
  ${qmk} flash --clean --keyboard "$keyboard" --keymap "$keymap" "$jsonfile"
''
