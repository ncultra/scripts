#!/bin/bash

xargs disown $($1) &

#xargs disown $(pidof $1) 
