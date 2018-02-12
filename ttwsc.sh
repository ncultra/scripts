#!/bin/bash
find ./ -name "*.c" | xargs ttws.sh
find ./ -name "*.h" | xargs ttws.sh
find ./ -name "Makefile" | xargs ttws.sh
