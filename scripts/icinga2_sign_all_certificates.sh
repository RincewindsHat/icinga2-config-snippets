#!/bin/bash


# Exit on error
set -e

# Debugging
#set -x

FINGERPRINTS=$(icinga2 ca list | tail -n +3 | awk '{print $1}')

while read fingerprint; do
        echo "Signing fingerprint: $fingerprint"
        icinga2 ca sign $fingerprint
done <<< $FINGERPRINTS

