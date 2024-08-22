#!/bin/bash

# Get the git diff and changed files
git_diff=$(git diff --summary -b)
changed_files=$(git diff --name-only | awk -F '.' '{print $1}')

prompt="This git diff describes changes made to Roblox's API using OpenAPI JSON documentation format. Summarize this diff in 7 words or less per file: $git_diff"

response=$(curl -s -X POST http://localhost:11434/api/generate -d "{\"model\": \"mistral\", \"prompt\": \"$prompt\"}")

json_data=$(echo "$response" | grep -o '{.*}' | tail -n 1)
summary=$(python -c "import json, sys; data=json.loads(sys.stdin.read()); print(data['response'])" <<< "$json_data")

git commit -m "$(printf "Generated Summary: %s\n%s" "$summary" "$changed_files")"
