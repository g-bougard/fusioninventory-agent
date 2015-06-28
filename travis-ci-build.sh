#! /bin/sh

set -e

echo "Installed packages:"
dpkg -l

echo "List of perl available versions:"
perlbrew list
echo

echo "Git status:"
git status
echo

echo "System info:"
ip addr
echo

echo "Let's go !!!"
echo

perl Makefile.PL

make test

