#!/bin/bash

# Fetch git diff and changed files
git_diff=$(git diff --summary -b)
changed_files=$(git diff --name-only)

# Construct prompt
prompt="This git diff describes changes made to Roblox's api using OpenAPI json documentation format. Summarize this diff in 7 words or less per file: $git_diff"
escaped_prompt=$(jq -Rn --arg p "$prompt" '$p')

# Get response from the API
response=$(curl -X POST http://localhost:11434/api/generate -d "{\"model\": \"mistral\", \"prompt\": $escaped_prompt}")

# Extract summary from the API response
summary=$(echo "$response" | jq -r '.response')

# Debugging (IGNORE)
echo "Git Diff: $git_diff"
echo "Changed Files: $changed_files"
echo "Prompt: $prompt"
echo "API Response: $response"
echo "Summary: $summary"

if [ -n "$summary" ]; then
    git commit -m "$(printf "Generated Summary: %s\nChanged Files: %s" "$summary" "$changed_files")"
else
    echo "Summary generation failed. Commit not created."
    exit 1
fi
