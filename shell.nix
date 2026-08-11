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
  '';
}