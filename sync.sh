#!/bin/bash
#############################
##############################
# Don't use uninitialised variables
set -u
# Exit if there are non-zero return values
set -e

echo Started sync at `date +"%Y-%m-%d_%X"`

# Command line args
if [ $# -ne 3 ] then
  echo "Usage: $0 [git project repo] [authors file] [email address for reporting errors]"
  exit
fi

export GIT_REPO=$1
export AUTHORS_FILE=$2
export MAIL_TO=$3

echo Running the script in `pwd`

# Update the local mirror
# Send an email if this failed (possibly due to incorrect authors-file)?
if ! git svn fetch --authors-file=$AUTHORS_FILE; then
  echo "Send failed"
  # Send mail
  mail -s 'git svn sync failed' $MAIL_TO &lt;&lt; _EOF
  Syncing git &lt;-&gt; svn failed
  _EOF
fi

# Do we need to update master?
lmaster=`git rev-parse --sq master`
rmaster=`git rev-parse --sq remotes/trunk`
now=`date`
echo "lmaster: ${lmaster}, rmaster: ${rmaster}"
if [ $lmaster != $rmaster ]; then
  echo "${now}: Updating master"
  git rebase remotes/trunk master
else
  echo "${now}: Master is up-to-date"
fi

for branch in `git branch | tr -d "* "`; do
  if [ $branch != "master" ]; then
    lstable=`git rev-parse --sq heads/${branch}`
    rstable=`git rev-parse --sq remotes/${branch}`
    echo "lstable: ${lstable}, rstable: ${rstable}"
    if [ $lstable != $rstable ]; then
      echo "${now}: Updating branch: ${branch}"
      git rebase remotes/${branch} ${branch}
    else
      echo "${now}: Branch '${branch}' is up-to-date"
    fi
  fi
done

doalarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }

doalarm 300 git push -v --all $GIT_REPO

# Update the date of the last sync
echo Successfully synced at `date +"%Y-%m-%d_%X"`
