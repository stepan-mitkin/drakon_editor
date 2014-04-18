#!/bin/bash

# Get the path to this script
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

# Build useful file and folder names
SKETCH="$SCRIPTPATH/south_norway"
OUT="$SCRIPTPATH/out"
GEN="$SCRIPTPATH/../../drakon_gen.tcl"

# Generate Processing.org .pde files from DRAKON .drn files
tclsh $GEN -in "$SCRIPTPATH/south_norway/Sky.drn"
tclsh $GEN -in "$SCRIPTPATH/south_norway/Displacement.drn"

# Compile and run
processing-java --sketch=$SKETCH --output=$OUT --force --run