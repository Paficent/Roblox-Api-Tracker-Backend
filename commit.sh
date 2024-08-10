#!/bin/bash

function ollama_query() {
  curl -X POST http://localhost:11434/api/generate -d "{\"model\": \"mistral\", \"prompt\": \"$1\"}"
}

git_diff=$(git diff)
prompt="Summarize this git diff into a useful, 10 words commit message in english: $git_diff"

response=$(ollama_query "$prompt")

commit_message=$(echo "$response" | jq '.response' | tr -d '"')
commit_message=$(echo "$commit_message" | tr -d '[:space:]')

# Perform the git commit
git commit -m "$commit_message"
