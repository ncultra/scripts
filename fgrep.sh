#! /usr/bin/env bash

grep $1 | grep -v grep | tail -$2
