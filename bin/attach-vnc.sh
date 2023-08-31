#!/usr/bin/env bash

set -eu -o pipefail

DISPLAY=:1 x0vncserver -rfbauth ~/.vnc/passwd
