#!/bin/bash
set -e

# Run the config generation script with all arguments
/usr/local/bin/hostbgp-config.sh "$@"

# If successful, start FRR as the base image would
# The base image uses /usr/lib/frr/docker-start as the entrypoint
exec /usr/lib/frr/docker-start
