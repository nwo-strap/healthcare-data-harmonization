#!/bin/bash

# This script will run code generation and compile export module
# This script uses ./build.sh as template

set -o errexit

PREREQUISITES=( protoc go )
PREREQUISITE_SOURCES=( "https://github.com/protocolbuffers/protobuf/releases" "https://golang.org/dl/" )
PREREQUISITE_VERSIONS=( "v3.11.4" "v1.17" )

function check_tools {
  LENGTH=${#PREREQUISITES[@]}
  for (( i=0; i<${LENGTH}; i++ ));
  do
    COMMAND=${PREREQUISITES[$i]}
    SOURCE=${PREREQUISITE_SOURCES[$i]}
    VERSION=${PREREQUISITE_VERSIONS[$i]}

    if ! [ -x "$(command -v $COMMAND)" ]; then
      echo "Error: $COMMAND is not available in the PATH. You can download it from $SOURCE (we recommend version ≥$VERSION) if you do not have it installed." >&2
      exit 1
    fi
  done
}

function absfilepath() {
  pushd $(dirname $1) > /dev/null
  base=$(pwd)
  popd > /dev/null
  echo $base/$(basename $1)
}

function go_mod_command {
  START=$(pwd)
  find . -name "go.mod" -print0 | while read -d $'\0' f
  do
    echo Entering $(dirname $(absfilepath "$f"))
    cd $(dirname $(absfilepath "$f"))
    go $1 ./...
    cd $START
  done
}

check_tools

source ./generate_protos.sh

# BEGIN LOCAL-MOD-REPLACE
cd ../mapping_language
source ./generate_grammar.sh
cd ../mapping_engine
# END LOCAL-MOD-REPLACE

cd main

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  go build -o libgoogle_whistle.so -buildmode=c-shared main.go exports.go
elif [[ "$OSTYPE" == "darwin"* ]]; then
  go build -o libgoogle_whistle.dylib -buildmode=c-shared main.go exports.go
else
  echo "Error: $OSTYPE is not supported. You can compile it on Linux or MacOS system."
  exit 1
fi