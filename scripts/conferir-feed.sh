#!/usr/bin/env bash
# Confere o feed de atualização gerado pelo electron-builder antes de virar asset da release.
# Uso: scripts/conferir-feed.sh <windows|macos|linux> <pasta release/> <tag vX.Y.Z>
set -euo pipefail

plataforma="${1:-}"
pasta="${2:-}"
tag="${3:-}"

erro() { echo "::error::$*"; exit 1; }

case "$plataforma" in
  windows) feed="latest.yml" ;;
  macos) feed="latest-mac.yml" ;;
  linux) feed="latest-linux.yml" ;;
  *) erro "Plataforma desconhecida: '$plataforma' (use windows, macos ou linux)." ;;
esac
[ -d "$pasta" ] || erro "Pasta $pasta não existe."
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || erro "A tag precisa ser vX.Y.Z."

arquivo="$pasta/$feed"
[ -f "$arquivo" ] || erro "$feed não foi gerado em $pasta: sem ele o app não acha a atualização."

# Valor de uma linha "chave: valor" do YAML do electron-builder, sem aspas.
valor() { sed -E "s/^[[:space:]-]*$1:[[:space:]]*//; s/^['\"]//; s/['\"][[:space:]]*\$//"; }

versao="$(grep -E '^version:' "$arquivo" | head -n1 | valor version)"
[ "v$versao" = "$tag" ] || erro "$feed diz versão '$versao', mas a tag é $tag."

nomes="$(grep -E '^[[:space:]-]*(url|path):' "$arquivo" | sed -E 's/^[[:space:]-]*(url|path):/x:/' | valor x | sort -u)"
[ -n "$nomes" ] || erro "$feed não lista nenhum arquivo."
while IFS= read -r nome; do
  # O GitHub troca caracteres fora deste conjunto no nome do asset, e o feed deixaria de achar o arquivo.
  [[ "$nome" =~ ^[A-Za-z0-9._-]+$ ]] || erro "Nome '$nome' em $feed tem caractere que o GitHub renomeia no asset."
  [ -f "$pasta/$nome" ] || erro "$feed cita $nome, que não está em $pasta."
  if [ "$plataforma" = windows ] && [[ "$nome" == *.exe ]] && [ ! -f "$pasta/$nome.blockmap" ]; then
    erro "Falta $nome.blockmap: sem ele toda atualização baixa o instalador inteiro."
  fi
done <<< "$nomes"

configs=()
while IFS= read -r -d '' f; do configs+=("$f"); done < <(find "$pasta" -type f -name app-update.yml -print0)
[ "${#configs[@]}" -gt 0 ] || erro "Nenhum app-update.yml no pacote: o app empacotado não saberia onde procurar atualização."
for f in "${configs[@]}"; do
  grep -qxE 'provider: github' "$f" || erro "$f não usa provider github."
  grep -qxE 'owner: PedroPCardoso' "$f" || erro "$f não aponta para owner PedroPCardoso."
  grep -qxE 'repo: operai-releases' "$f" || erro "$f não aponta para repo operai-releases."
  # Sem assinatura no Windows, publisherName faz o electron-updater recusar toda atualização.
  if grep -qE '^publisherName:' "$f"; then erro "$f tem publisherName, mas o instalador não é assinado."; fi
done

echo "Feed $feed ok: versão $versao, $(wc -l <<< "$nomes" | tr -d ' ') arquivo(s), ${#configs[@]} app-update.yml."
