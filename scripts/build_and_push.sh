#!/usr/bin/env bash
set -e

DEST_REPO_NAME="$1"
ECHO="$2"

echo "::group::🧹 Preparing directory"
rm _quarto.yml
cp _quarto-prod.yml _quarto.yml

# Remove files not building in ipynb
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

echo "::group::🚀 Pushing notebooks to $DEST_REPO_NAME"
uv run github-action-push-to-another-repository \
  --source-directory temp_notebooks/ \
  --destination-repository-username linogaliana \
  --destination-repository-name "$DEST_REPO_NAME" \
  --destination-github-username linogaliana \
  --user-email lino.galiana@insee.fr \
  --create-target-branch-if-needed \
  --reset-repo \
  --token "$API_TOKEN_GITHUB"
echo "::endgroup::"
