{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: rec {
    packages.x86_64-linux.default = packages.x86_64-linux.sqlite-zig;
    packages.x86_64-linux.sqlite-zig = nixpkgs.legacyPackages.x86_64-linux.stdenv.mkDerivation {
      name = "sqlite-zig";
      src = ./.;
      
      installPhase = ''
        mkdir -p $out
        cp src/sqlite3.zig $out
        cp src/error.zig $out
        cp dep/sqlite/sqlite3.c $out/
        cp dep/sqlite/sqlite3.h $out/
      '';
    };

    devShell.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [
        nixpkgs.legacyPackages.x86_64-linux.zig
        nixpkgs.legacyPackages.x86_64-linux.zls
      ];
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
