#! /bin/sh

set -e

git status

echo "Testing:"
egrep -r 'our\s+\$VERSION.*[0-9.]+.*;' lib

if [ "${TRAVIS_PULL_REQUEST}" != "yes" ]; then
	git checkout "${TRAVIS_BRANCH}"
	git fetch origin +refs/pull/1/merge:
	git checkout -qf FETCH_HEAD
fi

git branch -v

perl Makefile.PL

make test

