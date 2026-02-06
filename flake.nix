{
  description = "OwnDNS - private DNS server based on Unbound.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "owndns";
        tag = self.shortRev or "dirty";

        contents = with pkgs; [
          bash
          cacert
          curl
          unbound
        ];

        enableFakechroot = true;
        fakeRootCommands = with pkgs; ''
          mkdir -p etc/unbound var/lib/unbound bin

          ${dockerTools.shadowSetup}
          groupadd -r -g 1000 unbound
          useradd -r -u 1000 -g unbound -d /etc/unbound -s /sbin/nologin unbound

          cp ${dns-root-data}/root.key var/lib/unbound/root.key
          cp ${dns-root-data}/root.hints etc/unbound/root.hints

          rm -f etc/unbound/unbound.conf
          cp ${./config/unbound.conf} etc/unbound/unbound.conf

          cp ${./scripts/entrypoint.sh} bin/entrypoint
          chmod +x bin/entrypoint

          chown -R unbound:unbound etc var bin
          chmod 755 bin/unbound
          chmod 770 var/lib/unbound
        '';

        config = {
          User = "1000:1000";
          Entrypoint = [ "/bin/entrypoint" ];

          ExposedPorts = {
            "53/tcp" = {};
            "53/udp" = {};
          };

          Labels = {
            "org.opencontainers.image.revision" = self.rev or "dirty";
            "org.opencontainers.image.source" = "https://github.com/onnovalkering/owndns";
          };
        };
      };
    };
}
