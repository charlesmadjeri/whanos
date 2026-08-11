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
    git
  ];

  shellHook = ''
    echo "Whanos env ready: kubectl, doctl, ansible, make"
    export KUBECONFIG="$PWD/kubeconfig.yaml"
  '';
}