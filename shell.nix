with (import <nixpkgs> { }); mkShell {
buildInputs =
  [ just gcc ]
  ++ (lib.optionals stdenv.isLinux [ cmake ]);
}
