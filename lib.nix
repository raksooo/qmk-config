{ nixpkgs, ... }:

rec {
  qmkConfiguration =
    module:
    builtins.toJSON (
      if builtins.typeOf module != "lambda" then
        module
      else
        module {
          lib = nixpkgs.lib // {
            inherit util;
          };
        }
    );

  util =
    with nixpkgs.lib;
    with builtins;
    rec {
      repeat = size: value: genList (_: value) size;

      replaceAll = value: list: repeat (length list) value;
      replaceIndex = index: value: replaceIndex' index (_: value);
      replaceIndex' =
        index: fn: list:
        concatLists [
          (take index list)
          [ (fn (elemAt list index)) ]
          (drop (index + 1) list)
        ];
      replaceRange =
        start: replacementList: list:
        let
          end = start + length replacementList;
        in
        concatLists [
          (take start list)
          replacementList
          (drop end list)
        ];

      replaceAll2 = value: matrix: map (replaceAll value) matrix;
      replaceAll2' = fn: matrix: map (row: map fn row) matrix;
      replaceIndex2 =
        row: column: value:
        replaceIndex2' row column (_: value);
      replaceIndex2' =
        row: column: fn: matrix:
        replaceIndex row (replaceIndex' column fn (elemAt matrix row)) matrix;
      replaceRange2 =
        row: startColumn: replacementList: matrix:
        replaceIndex row (replaceRange startColumn replacementList (elemAt matrix row)) matrix;
    };
}
