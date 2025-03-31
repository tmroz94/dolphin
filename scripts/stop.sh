#!/bin/bash

SCRIPTS_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P );

(cd $(dirname $SCRIPTS_PATH); docker compose down;)