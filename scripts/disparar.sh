#!/usr/bin/env bash
# Dispara o workflow release.yml. Uso: scripts/disparar.sh vX.Y.Z [--publicar] [operai_ref]
set -euo pipefail

tag="${1:-}"
publicar=false
ref=""
shift || true
for arg in "$@"; do
  if [ "$arg" = "--publicar" ]; then publicar=true; else ref="$arg"; fi
done

if ! [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Uso: $0 vX.Y.Z [--publicar] [operai_ref]" >&2
  exit 2
fi

if ! gh api "repos/PedroPCardoso/operai-desktop/git/ref/tags/$tag" --silent 2>/dev/null; then
  echo "A tag $tag não existe em PedroPCardoso/operai-desktop." >&2
  exit 1
fi

args=(-f "tag=$tag")
[ "$publicar" = true ] && args+=(-f publicar=true)
[ -n "$ref" ] && args+=(-f "operai_ref=$ref")

gh workflow run release.yml -R PedroPCardoso/operai-releases "${args[@]}"
sleep 3
gh run list -R PedroPCardoso/operai-releases --workflow release.yml --limit 1 \
  --json url --jq '"Execução: " + .[0].url'
echo "Aprove os jobs no environment release pelo link acima."
