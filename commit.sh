#!/bin/bash

git_diff=$(git diff --summary -b)
changed_files=$(git diff --name-only | awk -F '.' '{print $1}')
prompt="This git diff describes changes made to Roblox's api using OpenAPI json documentation format. For example, if a route 'getAccountAge' is added, an example response would be 'Added route getAccountAge to PLACEHOLDER_API_NAME/PLACEHOLDER_VERSION.json.', of course replacing PLACEHOLDER_API_NAME and PLACEHOLDER_VERSION with the actual api name and version (version is usually v1.json). Summarize this diff in 7 words or less per file: $git_diff"

response=$(curl -X POST http://localhost:11434/api/generate -d "{\"model\": \"mistral\", \"prompt\": \"$prompt\"}")
python -c "import json, sys; print(json.loads(sys.stdin.read())['response'])" <<< "$response"

git commit -m "$(printf "Generated Summary: %s\n%s" "$response" "$changed_files")"
