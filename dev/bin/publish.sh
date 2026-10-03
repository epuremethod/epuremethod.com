#!/bin/bash
#
# Publish @epure/dev on its own beta counter, `0.1.0-beta.N`, raised on every
# publish whether the registry is local or remote. The version stays in
# package.json, so what was published is what is committed.
#
# Publish this before `create-epure`: the template names `@epure/dev`, and
# `pnpm sync` asks the registry what version to write.

set -e

cd "$(dirname "$0")/.."

# The registry is whatever npm is configured to use — `~/.npmrc`, a project
# `.npmrc`, or the environment. Nothing here pins one, so the same script
# publishes to the local verdaccio today and to a real registry the day the
# name settles.
REGISTRY=$(npm config get registry)
REGISTRY=${REGISTRY%/}

# The placeholder rule, enforced here rather than in each package.json: the
# name is not settled, so nothing publishes to a public registry under it.
case "$REGISTRY" in
"" | *registry.npmjs.org*)
  echo "npm's registry is '$REGISTRY'."
  echo "The name is a placeholder: nothing here publishes to a public registry."
  echo "Point npm at the local one — registry=http://localhost:4873 in ~/.npmrc."
  exit 1
  ;;
esac

# `npm ping` rather than curl: it resolves the address the way the publish
# will. curl tries every loopback family, so it answers for a registry npm
# cannot reach, which reads as a registry that lost its packages.
if ! npm ping --registry "$REGISTRY" >/dev/null 2>&1; then
  echo "npm cannot reach $REGISTRY. Run radif's bin/registry.sh first."
  echo "If it is running, npm and verdaccio may disagree on what localhost"
  echo "means; name the address in bin/registry.sh's listen: and here."
  exit 1
fi

# A token for whatever registry that is. Verdaccio never reads it; npm refuses
# to publish without one. This replaces the user config for the run, which is
# why the registry above was read first.
NPMRC=$(mktemp)
trap 'rm -f "$NPMRC"' EXIT
printf '//%s/:_authToken="local"\n' "${REGISTRY#*://}" >"$NPMRC"
export NPM_CONFIG_USERCONFIG=$NPMRC

VERSION=$(node -p '
  const at = require("./package.json").version
  const beta = at.match(/^(.*)-beta\.(\d+)$/)
  beta ? `${beta[1]}-beta.${Number(beta[2]) + 1}` : `${at.split("-")[0]}-beta.1`
')

pnpm res:build

# The agreement sends an assistant to `node_modules/<package>/llms.txt`, so a
# tarball without the reference must not publish. Asked of the pack list, not
# the checkout: a `.npmignore` can drop a file the checkout holds.
if ! npm pack --dry-run 2>&1 | grep -qE ' llms\.txt$'; then
  echo "@epure/dev would publish without llms.txt: the reference is missing from the tarball."
  exit 1
fi

npm --no-git-tag-version version "$VERSION" >/dev/null
pnpm publish --tag beta --access public --no-git-checks --registry "$REGISTRY"

# `latest` too, while every version is a prerelease: npm sets it on the first
# publish whatever the tag says and never moves it again, so a plain install
# would get the first beta forever. See radif's bin/publish.sh for the whole
# of it.
npm dist-tag add "@epure/dev@$VERSION" latest --registry "$REGISTRY"

echo
echo "Published @epure/dev@$VERSION to $REGISTRY"
