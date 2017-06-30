#!/bin/bash

xargs disown $($@) &>/dev/null &
