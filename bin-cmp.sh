#!/bin/bash

cmp --verbose $1 $2 | gawk '{printf "%08X %02X %02X\n", $1-1, strtonum(0$2), strtonum(0$3)}'
