#! /bin/sh

set -e

echo "List of perl available versions:"
perlbrew list
echo

echo "Git status:"
git status
echo

echo "Let's go !!!"
echo

perl Makefile.PL

make test

