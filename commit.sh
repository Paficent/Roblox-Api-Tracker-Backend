#!/bin/bash

# Get the git diff and changed files
git_diff=$(git diff --summary -b)
changed_files=$(git diff --name-only | awk -F '.' '{print $1}')

input="Summarize the following git diff in a commit message: $git_diff"
commit_message=$(ollama run tavernari/git-commit-message "$input")

# Check if the model returned a message
if [ -z "$commit_message" ]; then
  echo "Error: No commit message generated."
  exit 1
fi

# Commit changes with the generated message
git commit -m "$commit_message"
