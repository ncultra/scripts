#!/usr/bin/env bash

pushd ~/src/linux-tmpm
git fetch linux-next
git fetch --tags linux-next
git fetch git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
popd
