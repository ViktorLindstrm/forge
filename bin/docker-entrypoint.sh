#!/bin/sh
set -e

./bin/forge eval "Forge.Release.migrate()"

exec ./bin/forge start
