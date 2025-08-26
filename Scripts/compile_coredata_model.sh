#
//  compile_coredata_model.sh
//  GraphNext
//
//  Created by Valerio Buriani on 26/08/25.
//


#!/usr/bin/env bash
set -euo pipefail

SRC="Sources/GraphNext/Persistence/Resources/GraphNext.xcdatamodeld"
DST="Sources/GraphNext/Persistence/Resources/Compiled/GraphNext.momd"

mkdir -p "$(dirname "$DST")"
xcrun momc "$SRC" "$DST"

echo "Compiled Core Data model to: $DST"