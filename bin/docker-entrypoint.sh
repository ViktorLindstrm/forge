#!/bin/sh
set -e

if [ -z "$SECRET_KEY_BASE" ]; then
  export SECRET_KEY_BASE=$(./bin/forge eval ":crypto.strong_rand_bytes(48) |> Base.encode64() |> IO.puts()" 2>/dev/null | tr -d '\r\n')
fi

./bin/forge eval "Forge.Release.migrate()"

exec ./bin/forge start
