#!/usr/bin/env bash

export USERNAME=${USERNAME:-$USER}

# I have a ssh-config extry named the same as the nixosConiguration in the flake
# this allows me to use e.g. "sh deploy.sh ci-big" to deploy the ci-big
# configuration to the "ci-big" host.
nixos-rebuild switch --use-remote-sudo --flake .#$1 --build-host $USERNAME@$1 --target-host $USERNAME@$1