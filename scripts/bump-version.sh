#!/bin/bash

# ./scripts/bump-version.sh <new version>
# eg ./scripts/bump-version.sh "3.0.0-alpha.1"

set -eux

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR/..

NEW_VERSION="$1"

# Replace iOS `paylisherFlutterVersion` with the given version
perl -pi -e "s/paylisherFlutterVersion = \".*\"/paylisherFlutterVersion = \"$NEW_VERSION\"/" ios/Classes/PaylisherFlutterVersion.swift

# Replace Android `paylisherVersion` with the given version
perl -pi -e "s/paylisherVersion = \".*\"/paylisherVersion = \"$NEW_VERSION\"/" android/src/main/kotlin/com/paylisher/flutter/PaylisherVersion.kt

# Replace Flutter `version` with the given version
perl -pi -e "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
