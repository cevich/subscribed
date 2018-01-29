#!/bin/bash

set -e

PR_TYPOS="ec-oh | ro-el | fi-x.?me"
BR_TYPOS="fi-x.?up! | squa-sh! | do.*not.*me-rge"

# Add ansible.cfg to pick up roles path.
echo -e '[defaults]\nroles_path = ../' > ansible.cfg

# Galaxy would normally install this with a "cevich." prefix
# which is missing from github repo name
ROLENAME="$(basename $PWD)"
echo "$ROLENAME" | grep -q 'cevich' || ln -sfv "$ROLENAME" "../cevich.$ROLENAME"

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

source ./.travis_test.sh
