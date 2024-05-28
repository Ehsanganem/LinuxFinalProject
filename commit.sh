#!/bin/bash

# Check for the existence of the CSV file
CSV_FILE="tasks.csv"
if [ ! -f "$CSV_FILE" ]; then
    echo "CSV file not found!"
    exit 1
fi

# Read parameters
DEV_DESCRIPTION="$1"

# Get current branch name
BRANCH_NAME=$(git branch --show-current)
echo "Current branch: $BRANCH_NAME"

# Extract data from CSV
while IFS=, read -r BugID DateTime BranchName DevName Priority Description; do
    echo "Reading line: $BugID, $DateTime, $BranchName, $DevName, $Priority, $Description"
    if [ "$BranchName" == "$BRANCH_NAME" ]; then
        COMMIT_MSG="BugID:$BugID:$(date +%Y-%m-%d_%H-%M-%S):$BranchName:$DevName:$Priority:$Description"
        if [ -n "$DEV_DESCRIPTION" ]; then
            COMMIT_MSG="$COMMIT_MSG:$DEV_DESCRIPTION"
        fi
        echo "Committing with message: $COMMIT_MSG"
        git add .
        git commit -m "$COMMIT_MSG"
        git push origin "$BRANCH_NAME"
        exit 0
    fi
done < "$CSV_FILE"

echo "No matching branch found in CSV."
