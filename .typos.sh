#!/bin/bash

set -e

PR_TYPOS="ec-oh | ro-el | fi-x.?me"
BR_TYPOS="fi-x.?up! | squa-sh! | do.*not.*me-rge"
TYPOS="${PR_TYPOS}"
if [ "${TRAVIS_BRANCH:-master}" == "master" ]
then
    TYPOS="${PR_TYPOS} | ${BR_TYPOS}"
    ANCESTOR=$(git merge-base origin/master HEAD)
else
    ANCESTOR=$(git merge-base origin/$TRAVIS_BRANCH HEAD)
fi
TYPOS=$(echo "$TYPOS" | tr -d ' -')
[ $ANCESTOR != $(git rev-parse HEAD) ] || ANCESTOR="HEAD^"
echo "Checking against ${ANCESTOR} for conflict and whitespace problems:"
git diff --check ${ANCESTOR}..HEAD  # Silent unless problem detected
git log -p ${ANCESTOR}..HEAD -- . ':!.travis.yml' &> /tmp/commits_with_diffs
LINES=$(wc -l </tmp/commits_with_diffs)
if (( $LINES == 0 ))
then
    echo "FATAL: no changes found since ${ANCESTOR}"
    exit 3
fi
echo "Examining $LINES change lines for typos:"
set +e
egrep -a -i -2 --color=always "$TYPOS" /tmp/commits_with_diffs && exit 3
