{
  description = "OwnDNS - private DNS server based on Unbound.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      modules = import ./modules { inherit pkgs; };
      groupId = "1000";
      groupName = "unbound";
      userId = "1000";
      userName = "unbound";
    in
    {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "owndns";
        tag = self.shortRev or "dirty";
        created = "now";

        contents = with pkgs; [
          bash
          cacert
          coreutils
          curl
          gawk
          (unbound.override { withDynlibModule = true; })
        ];

        enableFakechroot = true;
        fakeRootCommands = with pkgs; ''
          mkdir -p \
            bin \
            etc/unbound/rpz \
            run/unbound \
            tmp \
            var/lib/unbound

          ${dockerTools.shadowSetup}
          groupadd -r -g ${groupId} ${groupName}
          useradd -r -u ${userId} -g ${groupName} -d /etc/unbound -s /sbin/nologin ${userName}

          cp ${dns-root-data}/root.key var/lib/unbound/root.key
          cp ${dns-root-data}/root.hints etc/unbound/root.hints

          rm -f etc/unbound/unbound.conf
          cp ${./config/unbound.conf} etc/unbound/unbound.conf

          cp ${modules.punyblock}/lib/punyblock.so etc/unbound/punyblock.so

          cp ${./scripts/entrypoint.sh} bin/entrypoint
          cp ${./scripts/update-blocklists.sh} bin/update-blocklists
          chmod +x bin/entrypoint bin/update-blocklists

          chown -R ${userName}:${groupName} bin etc run tmp var
          chmod 755 bin/unbound
          chmod 770 etc/unbound/rpz var/lib/unbound
        '';

        config = {
          User = "${userId}:${groupId}";
          Entrypoint = [ "/bin/entrypoint" ];

          ExposedPorts = {
            "53/tcp" = { };
            "53/udp" = { };
          };

          Env = [
            "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
          ];

          Labels = {
            "org.opencontainers.image.revision" = self.rev or "dirty";
            "org.opencontainers.image.source" = "https://github.com/onnovalkering/owndns";
          };
        };
      };
    };
}
