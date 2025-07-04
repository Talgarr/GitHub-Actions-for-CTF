#!/bin/bash

HELP_MESSAGE="""Usage: $0 --org <organization> --challenge-repo <repo> --username <username> --action <action> \n
\n
Options: \n
  --challenge-repo, -c   The target repository template to generate the challenge.\n
  --org, -o              The organization where the challenges are.\n
  --username, -u         The github username to create the challenge for.\n
  --action, -a           The action to execute. (create, delete)\n
  --help, -h             Show this help message.\n
"""

if [[ "$#" -eq 0 ]]; then
  echo -e $HELP_MESSAGE
  exit 0
fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --org|-o) ORGANIZATION="$2"; shift ;;
    --challenge-repo|-c) CHALLENGE_REPO="$2"; shift ;;
    --username|-u) USERNAME="$2"; shift ;;
    --action|-a) ACTION="$2"; shift ;;
    --help|-h)
      echo -e $HELP_MESSAGE
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if [ -z "$ORGANIZATION" ]; then
  echo "Error: --org is required."
  exit 1
fi

if [ -z "$CHALLENGE_REPO" ]; then
  echo "Error: --challenge-repo is required."
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "Error: --username is required."
  exit 1
fi

if [ -z "$ACTION" ]; then
  echo "Error: --action is required."
  exit 1
fi

if ! gh api "/users/$USERNAME" --silent; then
  echo "Error: GitHub user '$USERNAME' does not exist."
  exit 1
fi

REPO_NAME="$CHALLENGE_REPO-$USERNAME"

case "$ACTION" in
  create)
    echo "Creating challenge for $USERNAME from template $CHALLENGE_REPO..."
    if gh repo view "$ORGANIZATION/$REPO_NAME" >/dev/null 2>&1; then
        echo "Error: Repository $ORGANIZATION/$REPO_NAME already exists."
        exit 1
    fi
    gh repo create "$ORGANIZATION/$REPO_NAME" \
      --template "$ORGANIZATION/$CHALLENGE_REPO" \
      --private \
      --description "Challenge for $USERNAME based on $CHALLENGE_REPO"

    if [ $? -ne 0 ]; then
        echo "Failed to create repository $ORGANIZATION/$REPO_NAME."
        exit 1
    fi

    echo "Adding $USERNAME as a collaborator with read permissions..."
    gh api --method PUT "/repos/$ORGANIZATION/$REPO_NAME/collaborators/$USERNAME" -f 'permission=read' >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Failed to add $USERNAME as a collaborator."
        gh repo delete "$ORGANIZATION/$REPO_NAME" --yes
        exit 1
    fi

    echo "Challenge repository created: https://github.com/$ORGANIZATION/$REPO_NAME"
    ;;

  delete)
    echo "Deleting challenge repository for $USERNAME..."
    if ! gh repo view "$ORGANIZATION/$REPO_NAME" >/dev/null 2>&1; then
        echo "Repository $ORGANIZATION/$REPO_NAME does not exist. Nothing to delete."
        exit 1
    fi
    gh repo delete "$ORGANIZATION/$REPO_NAME" --yes

    if [ $? -ne 0 ]; then
        echo "Failed to delete repository $ORGANIZATION/$REPO_NAME."
        exit 1
    fi

    echo "Challenge repository deleted successfully."
    ;;

  recreate)
    echo "Recreating challenge for $USERNAME..."
    $0 --org "$ORGANIZATION" --challenge-repo "$CHALLENGE_REPO" --username "$USERNAME" --action delete
    if [ $? -ne 0 ]; then
        echo "Error during delete step of recreate. Aborting."
        exit 1
    fi
    $0 --org "$ORGANIZATION" --challenge-repo "$CHALLENGE_REPO" --username "$USERNAME" --action create
    ;;

  *)
    echo "Error: Invalid action '$ACTION'. Allowed actions are 'create' or 'delete'."
    exit 1
    ;;
esac
