#!/bin/bash

rm -rf docs

cd apps/j2m/

fvm flutter clean
fvm flutter pub get

# for gh pages
# fvm flutter build web --base-href=/j2m/

# for cloudflare
fvm flutter build web

cd ../../

cp -r apps/j2m/build/web/ docs
