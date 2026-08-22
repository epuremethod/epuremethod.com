#!/bin/bash
#
# Publish @epure/create on its own beta counter, `0.1.0-beta.N`, raised on
# every publish whether the registry is local or remote. The version stays in
# package.json, so what was published is what is committed.
#
# Run `pnpm sync` and commit before this: the template must carry the versions
# it was tested at.

set -e

cd "$(dirname "$0")/.."

REGISTRY=http://localhost:4873
NPMRC=${EPURE_NPMRC:-$HOME/work/sylva/.registry/npmrc}
export NPM_CONFIG_USERCONFIG=$NPMRC

if ! curl -sf -o /dev/null "$REGISTRY"; then
  echo "No registry at $REGISTRY. Run sylva's bin/registry.sh first."
  exit 1
fi

VERSION=$(node -p '
  const at = require("./package.json").version
  const beta = at.match(/^(.*)-beta\.(\d+)$/)
  beta ? `${beta[1]}-beta.${Number(beta[2]) + 1}` : `${at.split("-")[0]}-beta.1`
')

pnpm agreement
pnpm res:build

npm --no-git-tag-version version "$VERSION" >/dev/null
pnpm publish --tag beta --access public --no-git-checks --registry "$REGISTRY"

echo
echo "Published @epure/create@$VERSION to $REGISTRY"
