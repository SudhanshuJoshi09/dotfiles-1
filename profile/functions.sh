#!/usr/bin/env bash

# run a command in multiple directories
eachdir() {
  pattern=$1
  command="${@:2}"
  baseDirName=$(basename `pwd`)

  for dir in `find $1 -type d -maxdepth 1 -mindepth 1`; do

    (cd $dir
    currentBranch=$(if [ -d ".git" ]; then; echo "\033[1;34mgit:(\033[0m\033[1;31m`git symbolic-ref --short HEAD`\033[0m\033[1;34m)\033[0m"; fi)
     echo "\033[0;32m➜\033[0m  \033[1m$baseDirName/\033[0m\033[1;36m$(basename `pwd`)\033[0m $currentBranch"; eval $command)
  done
}

# get the ISO8601 time
t() {
  date +"%Y-%m-%dT%H:%M"
}
