{
  description = "A CRT screen shader for Hyprland (decoration:screen_shader)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.runCommandLocal "hyprcrt-shader" { } ''
            mkdir -p $out/share/hyprCRT $out/bin
            install -Dm444 ${./crt.frag} $out/share/hyprCRT/crt.frag
            for f in ${./presets}/*.frag; do
              install -Dm444 "$f" "$out/share/hyprCRT/presets/$(basename "$f")"
            done
            install -Dm755 ${./toggle.sh} $out/share/hyprCRT/toggle.sh
            ln -s $out/share/hyprCRT/toggle.sh $out/bin/hyprcrt-toggle
          '';
        }
      );

      apps = forAllSystems (system: {
        toggle = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/hyprcrt-toggle";
        };
        default = self.apps.${system}.toggle;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
