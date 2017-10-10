#!/bin/bash

# Publish fresh versions of the user documentation in HTML, PDF, and ePub.
# Push to the gh-pages branch to publish to
# https://solutionguidance.github.io/psm/ .
# For use by PSM developers who already have up-to-date local checkouts
# of the PSM repository.
# Before running, ensure that you have committed any local changes
# in your current branch, and that you're in the repository root.

# Code partially adapted from
# https://benlimmer.com/2013/12/26/automatically-publish-javadoc-to-gh-pages-with-travis-ci/

set -x  # Avoiding -e because we need an exit code on `git diff`

if [[ $("pwd") != $("git rev-parse --show-toplevel") ]]
then
    set +x
    echo "Please run this from the root of the project by running:"
    echo "   ./scripts/push-userdocs-to-gh-pages.sh"
    echo "This script switches branches;"
    echo "running from the root ensures you won't end up in a deleted directory."
    exit 1
fi

echo "Building userdocs..."
cd psm-app || exit 1
./gradlew userhelp:{clean,html,pdf,epub}  || exit 1
cp -R userhelp/build /tmp/userdocs-latest  || exit 1

echo "Publishing Sphinx userdocs..."
cd .. || exit 1
git fetch git@github.com:solutionguidance/psm.git gh-pages  || exit 1
git rev-parse --verify --quiet "gh-pages"  # Check whether branch exists
if [ $? == 0 ]  # Check for truth
then
    git checkout gh-pages || exit 1  #  Will fail if you have uncommitted local changes.
    git pull git@github.com:solutionguidance/psm.git gh-pages
else
    git fetch git@github.com:solutionguidance/psm.git gh-pages:gh-pages
    git checkout gh-pages || exit 1 #  Will fail if you have uncommitted local changes.
fi

git rm -rf ./userdocs  || exit 1
mkdir -p userdocs/books  || exit 1
cp -Rf /tmp/userdocs-latest/html ./userdocs/html  || exit 1
cp -Rf /tmp/userdocs-latest/latex/ProviderScreeningModuleusermanual.pdf \
   /tmp/userdocs-latest/epub/ProviderScreeningModuleusermanual.epub \
   ./userdocs/books  || exit 1
git add -f ./userdocs/.  || exit 1

git diff --staged --quiet  # Check for changed files
if [ $? == 1 ]  # Check for differences
then
    git commit -m "Publish user docs and push to gh-pages"
    git push -q git@github.com:solutionguidance/psm.git gh-pages
    echo "Published Sphinx userdocs to gh-pages branch."
else
    echo "No changes; nothing to commit."
fi

# Return to branch and directory where user started

git checkout -

# Suggest removal of temp files in /tmp/userdocs-latest/
