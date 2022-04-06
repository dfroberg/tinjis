#!/bin/bash
PROJECTDIR=$(git rev-parse --show-toplevel)
cd $PROJECTDIR/antaeus
./build.sh
cd $PROJECTDIR/payment
./build.sh
cd $PROJECTDIR