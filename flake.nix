{
  description = "OwnDNS - private DNS server based on Unbound.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      unboundConfig = pkgs.writeText "unbound.conf" ''
        server:
          interface: 0.0.0.0
          port: 53

          # Allow common internal container network and local ranges.
          access-control: 10.0.0.0/8 allow
          access-control: 127.0.0.0/8 allow
          access-control: 172.16.0.0/12 allow
          access-control: 192.168.0.0/16 allow

          # Root files for recursive resolution and DNSSEC validation.
          auto-trust-anchor-file: "/var/lib/unbound/root.key"
          root-hints: "/etc/unbound/root.hints"

          # Security & Privacy
          aggressive-nsec: yes
          harden-below-nxdomain: yes
          harden-dnssec-stripped: yes
          harden-glue: yes
          hide-identity: yes
          hide-version: yes
          qname-minimisation: yes
          use-caps-for-id: yes

          # Performance
          cache-max-ttl: 86400
          cache-min-ttl: 3600
          infra-cache-slabs: 4
          key-cache-slabs: 4
          msg-cache-size: 256m
          msg-cache-slabs: 4
          num-threads: 4
          prefetch-keys: yes
          prefetch: yes
          rrset-cache-size: 512m
          rrset-cache-slabs: 4
          rrset-roundrobin: yes
          serve-expired-ttl: 3600
          serve-expired: yes

          # Disable internal chroot and uid switch.
          chroot: ""
          username: ""

          # Logging
          logfile: ""
          verbosity: 1
      '';

    in {
      packages.${system}.default = pkgs.dockerTools.buildLayeredImage {
        name = "owndns";
        tag = "0.1.0";

        contents = with pkgs; [
          cacert
          coreutils
          dns-root-data
          libcap
          unbound
        ];

        # Redirect absolute paths to the build directory.
        enableFakechroot = true;

        fakeRootCommands = with pkgs; ''
          mkdir -p etc/unbound var/lib/unbound bin

          ${dockerTools.shadowSetup}
          groupadd -r -g 1000 unbound
          useradd -r -u 1000 -g unbound -d /etc/unbound -s /sbin/nologin unbound

          cp ${dns-root-data}/root.key var/lib/unbound/root.key
          cp ${dns-root-data}/root.hints etc/unbound/root.hints

          rm -f etc/unbound/unbound.conf
          cp ${unboundConfig} etc/unbound/unbound.conf

          chown -R unbound:unbound etc var bin
          chmod 755 bin/unbound
          chmod 770 var/lib/unbound
        '';

        config = {
          User = "1000:1000";
          Cmd = [ "/bin/unbound" "-d" "-c" "/etc/unbound/unbound.conf" ];
          ExposedPorts = {
            "53/udp" = {};
          };
        };
      };
    };
}
