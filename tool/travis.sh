#!/usr/bin/env bash

# Fast fail the script on failures.
# and print line as they are read
set -ex

flutter --version

pushd sqflite_porter
flutter packages get
tool/travis.sh
popd

pushd sqflite_server
flutter packages get
tool/travis.sh
popd

pushd sqflite_test
flutter packages get
tool/travis.sh
popd

pushd sqflite_test_app
flutter packages get
tool/travis.sh
popd

pushd sqflite_server_app
flutter packages get
tool/travis.sh
popd

pushd alt/sqflite_github_test
flutter packages get
tool/travis.sh
popd
