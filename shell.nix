{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    gnumake
    docker-compose
    kubectl
    doctl
    ansible
    ansible-lint   # optional
    yq-go          # optional local checks; Jenkins image has its own yq
    terraform
    git
  ];

  shellHook = ''
    echo "Whanos env ready: kubectl, doctl, ansible, terraform, make"
    export KUBECONFIG="$PWD/kubeconfig.yaml"
    if [ -f "$PWD/.env" ]; then
      set -a
      # shellcheck disable=SC1091
      . "$PWD/.env"
      set +a
      if [ -n "''${DIGITALOCEAN_TOKEN:-}" ] && [ -z "''${DIGITALOCEAN_ACCESS_TOKEN:-}" ]; then
        export DIGITALOCEAN_ACCESS_TOKEN="$DIGITALOCEAN_TOKEN"
      fi
      if [ -n "''${DIGITALOCEAN_ACCESS_TOKEN:-}" ] && [ -z "''${DIGITALOCEAN_TOKEN:-}" ]; then
        export DIGITALOCEAN_TOKEN="$DIGITALOCEAN_ACCESS_TOKEN"
      fi
      echo "Loaded .env (DIGITALOCEAN_TOKEN for doctl/terraform)"
    else
      echo "Tip: cp .env.example .env  # for DIGITALOCEAN_TOKEN"
    fi
  '';
}