#!/usr/bin/env bash


while (( $# > 0 ))
do
    case $(expr substr $1 1 1) in
	'-' )
	      case $(expr substr $1 2 1) in
		  'k' ) echo "$(expr substr $1 2 1)";;
		   * )  echo "$(expr substr $1 2 1)";;
	      esac
	      ;;
    esac
    shift
done


KERNEL_NAME=$(ssh root@10.227.48.50 "uname -r")

echo $KERNEL_NAME
