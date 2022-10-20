#!/bin/sh

set -e

cd "$(dirname "$0")"
cd Tests
rm -fr Unity
git clone https://github.com/ThrowTheSwitch/Unity/
cd ..
git submodule update --init
