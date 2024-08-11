#!/bin/bash

git_diff=$(git diff -summary -b)
changed_files=$(git diff --name-only | awk -F '.' '{print $1}')
prompt="This git diff describes changes made to Roblox's api using OpenAPI json documentation format. For example, if a route 'getAccountAge' is added, an example response would be 'Added route getAccountAge to JSON_FILE_NAME_PLACEHOLDER.', of course replacing with the actual json file name. Summarize this diff in 7 words or less per file: $git_diff"

response=$(curl -X POST http://localhost:11434/api/generate -d "{\"model\": \"mistral\", \"prompt\": \"$prompt\"}")
python -c "import json, sys; print(json.loads(sys.stdin.read())['response'])" <<< "$response"

git commit -m "Ai Generated Summary: $commit_message\nFiles Changed: $changsd_files"
