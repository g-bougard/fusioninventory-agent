#! /bin/sh

set -e

echo "Install more perl lib..."
cpanm --quiet --notest Net::NBName
cpanm --quiet --notest Parse::EDID
echo

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

