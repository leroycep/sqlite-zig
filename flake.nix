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
      
      propogatedBuildInputs = [
        nixpkgs.legacyPackages.x86_64-linux.sqlite
      ];

      installPhase = ''
        mkdir -p $out/sqlite-zig
        install src/bind.zig $out/sqlite-zig/
        install src/c.zig $out/sqlite-zig/
        install src/error.zig $out/sqlite-zig/
        install src/sqlite3.zig $out/sqlite-zig/
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
