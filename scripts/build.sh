#!/bin/bash

cd apps/j2m/

fvm flutter clean
fvm flutter pub get
fvm flutter build web --base-href=/j2m/

cd ../../

rm -rf docs

cp -r apps/j2m/build/web/ docs
