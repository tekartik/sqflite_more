#!/usr/bin/env bash

# Fast fail the script on failures.
# and print line as they are read
set -ev

flutter analyze --no-current-package lib
flutter test
