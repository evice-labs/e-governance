{
  description = "Logos Governance Module for Logos Basecamp";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    e_wallet_core.url = "github:evice-labs/e-wallet-core";
    wallez-kit = {
      url = "github:evice-labs/wallez-kit/v2.0.0";
      flake = false;
    };
  };

  outputs = inputs@{ logos-module-builder, wallez-kit, ... }:
    let
      moduleOutputs = logos-module-builder.lib.mkLogosQmlModule {
        src = ./.;
        configFile = ./metadata.json;
        flakeInputs = inputs;
      };
      nixpkgs = logos-module-builder.inputs.nixpkgs;
      nix-bundle-lgx = logos-module-builder.inputs.nix-bundle-lgx;
      nix-bundle-logos-module-install = logos-module-builder.inputs.nix-bundle-logos-module-install;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      packages = nixpkgs.lib.genAttrs supportedSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          baseSysPkgs = moduleOutputs.packages.${system};
          withWallezKit = (pkgs.runCommand "logos-dao_miniapp-module" {} ''
            cp -a ${baseSysPkgs.default} $out
            chmod -R u+w $out
            rm -rf $out/lib/qml/WallezKit
            mkdir -p $out/lib/qml/WallezKit
            cp -r ${wallez-kit}/. $out/lib/qml/WallezKit/
          '') // {
            inherit (baseSysPkgs.default) src version lgxAssets;
          };
        in
        baseSysPkgs // {
          default = withWallezKit;
          lgx = nix-bundle-lgx.bundlers.${system}.default withWallezKit;
          lgx-portable = nix-bundle-lgx.bundlers.${system}.portable withWallezKit;
          install = nix-bundle-logos-module-install.bundlers.${system}.dev withWallezKit;
          install-portable = nix-bundle-logos-module-install.bundlers.${system}.portable withWallezKit;
        }
      );

      extraChecks = nixpkgs.lib.genAttrs supportedSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          qmllint = pkgs.runCommand "qmllint-check" {
            nativeBuildInputs = [ pkgs.qt6.qtdeclarative ];
          } ''
            mkdir -p qml
            cp -r ${./qml}/. qml/
            chmod -R u+w qml
            rm -rf qml/WallezKit
            mkdir -p qml/WallezKit
            cp -r ${wallez-kit}/. qml/WallezKit/
            for file in $(find qml -name "*.qml" | sort); do
              qmllint -I qml/controls -I qml/theme -I qml/views -I qml/state -I qml/WallezKit "$file"
            done
            touch $out
          '';
        }
      );
    in
    moduleOutputs // {
      inherit packages;
      checks = nixpkgs.lib.recursiveUpdate moduleOutputs.checks extraChecks;
    };
}
