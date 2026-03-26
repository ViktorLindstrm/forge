#!/bin/sh
set -e

if [ -z "$SECRET_KEY_BASE" ]; then
  export SECRET_KEY_BASE=$(openssl rand -base64 48 | tr -d '\r\n')
fi

./bin/forge eval "Forge.Release.migrate()"

exec ./bin/forge start
