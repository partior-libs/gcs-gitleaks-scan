#!/bin/bash

INPUT_CONFIG_PATH="$1"
CONFIG=""

# check if a custom config have been provided
if [ -f "$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH" ]; then
  CONFIG=" --config-path=$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH"
fi

echo running gitleaks "$(gitleaks version) with the following command👇"

DONATE_MSG="👋 maintaining gitleaks takes a lot of work so consider sponsoring me or donating a little something\n\e[36mhttps://github.com/sponsors/zricethezav\n\e[36mhttps://www.paypal.me/zricethezav\n"
echo [DEBUG] Listing...
baseDir=$(pwd)
cd $GITHUB_WORKSPACE
pwd
ls -ltrah ./
echo [DEBUG] Add safe..
git config --add safe.directory $GITHUB_WORKSPACE
# ls -ltrah $GITHUB_WORKSPACE
echo [DEBUG] Git config...
# ls -ltrah /github/home/.gitconfig
# ls -ltrah /github/home/
# git config --global --add safe.directory /github/workspace
# git version
git config --get-all safe.directory
cd $baseDir
echo [DEBUG] Git config... end
if [ "$GITHUB_EVENT_NAME" = "push" ]
then
  echo gitleaks detect --source=$GITHUB_WORKSPACE --verbose --redact $CONFIG
  CAPTURE_OUTPUT=$(gitleaks detect --source=$GITHUB_WORKSPACE --verbose --redact $CONFIG)
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]
then 
  echo [INFO] Getting commits...
  git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick  remotes/origin/$GITHUB_BASE_REF..HEAD
  COMMIT_LIST=$(git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF..HEAD)
  for eachCommit in $COMMIT_LIST
  do
    echo [INFO] Checking commit $eachCommit
    if [[ ! -z $commit_range ]];then
      commit_range=$eachCommit..$commit_range
    else
      commit_range=$eachCommit
    fi 
  done
  echo gitleaks detect --source=$GITHUB_WORKSPACE --verbose --redact --log-opts="--all ${commit_range}" $CONFIG
  CAPTURE_OUTPUT=$(gitleaks detect --source=$GITHUB_WORKSPACE --verbose --redact --log-opts="--all ${commit_range}" $CONFIG)
fi

if [ $? -eq 1 ]
then
  GITLEAKS_RESULT=$(echo -e "\e[31m🛑 STOP! Gitleaks encountered leaks")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::$GITLEAKS_RESULT"
  echo "----------------------------------"
  echo "$CAPTURE_OUTPUT"
  echo "::set-output name=result::$CAPTURE_OUTPUT"
  echo "----------------------------------"
  echo -e $DONATE_MSG
  exit 1
else
  GITLEAKS_RESULT=$(echo -e "\e[32m✅ SUCCESS! Your code is good to go!")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::$GITLEAKS_RESULT"
  echo "------------------------------------"
  echo -e $DONATE_MSG
fi
