{
  description = "azurite.cr Spoke - crystal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openspec.url = "github:Fission-AI/OpenSpec";
  };

  outputs = { self, nixpkgs, openspec }:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

# Crystal 1.19.1 module definition
# Use pkgs.crystal (default in nixpkgs is 1.19.1)
crystal = pkgs.crystal;

      # Read flake.private.nix for per-developer overrides (like fetcher.cr)
      # This allows developers to provide custom shellHook, etc.
      privateConfig =
        if builtins.pathExists ./flake.private.nix then
          let
            content = builtins.readFile ./flake.private.nix;
            try_with_args = builtins.tryEval (import ./flake.private.nix { inherit pkgs; });
            try_no_args = builtins.tryEval (import ./flake.private.nix);
          in
            if builtins.substring 0 2 content == "#!" then {}
            else if try_with_args.success then try_with_args.value
            else if try_no_args.success then (if try_no_args.value ? outputs then {} else try_no_args.value)
            else {}
        else {};

      # Get shellHook from privateConfig if provided
      privateShellHook = if privateConfig ? shellHook then privateConfig.shellHook else "";

pwLibs = with pkgs; [ sqlite.dev ];

    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ crystal openspec.packages.${system}.default ] ++ pwLibs;

        shellHook = ''
          echo "azurite.cr DevShell Active"
           '' + privateShellHook;
      };
    };
}