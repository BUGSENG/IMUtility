#!/bin/sh

set -e

cd "$(dirname "$0")"
git clone https://github.com/ThrowTheSwitch/Unity/
git submodule update --init
