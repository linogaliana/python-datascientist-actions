#!/usr/bin/env bash
set -e

DEST_REPO_NAME="$1"
ECHO="$2"


echo "::group::🧹 Preparing directory"
rm _quarto.yml
cp _quarto-prod.yml _quarto.yml
rm index.qmd
rm -rf content/git/
rm content/annexes/evaluation.qmd
echo "::endgroup::"


echo "::group::🚀 Converting to ipynb"
export QUARTO_PROFILE=fr,en
if [ "$ECHO" == "true" ]; then
  ECHO_FLAG="-M echo:true"
else
  ECHO_FLAG=""
fi

uv run quarto render --profile fr --to ipynb --execute $ECHO_FLAG
uv run quarto render --profile en --to ipynb --execute $ECHO_FLAG
echo "::endgroup::"


echo "::group::📦 Moving files"
mkdir -p temp_notebooks/notebooks
uv run build/move_files.py --direction temp_notebooks/notebooks
echo "::endgroup::"


echo "::group::🔁 Pushing to ${DEST_REPO_NAME}"
gh workflow run linogaliana/github-action-push-to-another-repository@main \
  --repo linogaliana/"$DEST_REPO_NAME" \
  --env API_TOKEN_GITHUB="${API_TOKEN_GITHUB}" \
  --ref main \
  --json '{
    "source-directory": "temp_notebooks/",
    "destination-repository-username": "linogaliana",
    "destination-repository-name": "'"${DEST_REPO_NAME}"'",
    "user-email": "lino.galiana@insee.fr",
    "destination-github-username": "linogaliana",
    "create-target-branch-if-needed": true,
    "reset-repo": true
  }'
echo "::endgroup::"
