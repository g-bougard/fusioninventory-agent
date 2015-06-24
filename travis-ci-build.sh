#! /bin/sh

set -e

perlbrew list

git status

perl Makefile.PL

make test

