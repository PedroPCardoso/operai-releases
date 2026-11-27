#!/usr/bin/env bash
# Testes de scripts/conferir-feed.sh com pastas release/ falsas. Uso: tests/conferir-feed.test.sh
set -uo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
script="$raiz/scripts/conferir-feed.sh"
falhas=0

feed_ok() {
  printf 'owner: PedroPCardoso\nrepo: operai-releases\nprovider: github\nreleaseType: release\nupdaterCacheDirName: operai-desktop-updater\n'
}

# monta uma pasta release/ válida para a plataforma em $1, versão $2
montar() {
  local dir plataforma="$1" versao="$2"
  dir="$(mktemp -d)"
  case "$plataforma" in
    windows)
      mkdir -p "$dir/win-unpacked/resources"
      feed_ok > "$dir/win-unpacked/resources/app-update.yml"
      : > "$dir/OperaiBot-$versao-setup.exe"
      : > "$dir/OperaiBot-$versao-setup.exe.blockmap"
      cat > "$dir/latest.yml" <<YML
version: $versao
files:
  - url: OperaiBot-$versao-setup.exe
    sha512: abc
    size: 1
path: OperaiBot-$versao-setup.exe
sha512: abc
releaseDate: '2026-11-27T00:00:00.000Z'
YML
      ;;
    macos)
      mkdir -p "$dir/mac-arm64/OperaiBot.app/Contents/Resources" "$dir/mac/OperaiBot.app/Contents/Resources"
      feed_ok > "$dir/mac-arm64/OperaiBot.app/Contents/Resources/app-update.yml"
      feed_ok > "$dir/mac/OperaiBot.app/Contents/Resources/app-update.yml"
      for a in arm64 x64; do
        : > "$dir/OperaiBot-$versao-$a.zip"; : > "$dir/OperaiBot-$versao-$a.dmg"
      done
      cat > "$dir/latest-mac.yml" <<YML
version: $versao
files:
  - url: "OperaiBot-$versao-arm64.zip"
    sha512: abc
    size: 1
  - url: 'OperaiBot-$versao-x64.zip'
    sha512: abc
    size: 1
path: OperaiBot-$versao-arm64.zip
sha512: abc
YML
      ;;
    linux)
      mkdir -p "$dir/linux-unpacked/resources"
      feed_ok > "$dir/linux-unpacked/resources/app-update.yml"
      : > "$dir/OperaiBot-$versao.AppImage"
      cat > "$dir/latest-linux.yml" <<YML
version: $versao
files:
  - url: OperaiBot-$versao.AppImage
    sha512: abc
    size: 1
path: OperaiBot-$versao.AppImage
sha512: abc
YML
      ;;
  esac
  echo "$dir"
}

espera() { # espera <0|1> <descrição> <trecho esperado na saída> <comando...>
  local quer="$1" nome="$2" trecho="$3"; shift 3
  local saida codigo
  saida="$("$@" 2>&1)"; codigo=$?
  if { [ "$quer" = 0 ] && [ "$codigo" -eq 0 ]; } || { [ "$quer" = 1 ] && [ "$codigo" -ne 0 ]; } && [[ "$saida" == *"$trecho"* ]]; then
    echo "ok   - $nome"
  else
    echo "FALHA - $nome (saída $codigo)"; printf '       %s\n' "$saida"
    falhas=$((falhas + 1))
  fi
}

for p in windows macos linux; do
  d="$(montar "$p" 0.1.150)"
  espera 0 "$p: pasta válida passa" "Feed " "$script" "$p" "$d" v0.1.150
done

d="$(montar windows 0.1.150)"; rm "${d:?}/latest.yml"
espera 1 "windows: sem latest.yml falha" "latest.yml não foi gerado" "$script" windows "$d" v0.1.150

d="$(montar windows 0.1.150)"; rm "${d:?}/OperaiBot-0.1.150-setup.exe"
espera 1 "windows: arquivo citado no feed ausente falha" "que não está em" "$script" windows "$d" v0.1.150

d="$(montar windows 0.1.150)"; rm "${d:?}/OperaiBot-0.1.150-setup.exe.blockmap"
espera 1 "windows: sem blockmap do instalador falha" ".blockmap" "$script" windows "$d" v0.1.150

d="$(montar macos 0.1.150)"; rm "${d:?}/OperaiBot-0.1.150-x64.zip"
espera 1 "macos: zip x64 citado e ausente falha" "cita OperaiBot-0.1.150-x64.zip" "$script" macos "$d" v0.1.150

d="$(montar windows 0.1.150)"
espera 1 "versão do feed diferente da tag falha" "mas a tag é v0.1.151" "$script" windows "$d" v0.1.151

d="$(montar linux 0.1.150)"; sed -i.bak 's/^owner: .*/owner: milind-soni/' "$d/linux-unpacked/resources/app-update.yml"
espera 1 "app-update.yml do upstream falha" "owner PedroPCardoso" "$script" linux "$d" v0.1.150

d="$(montar linux 0.1.150)"; sed -i.bak 's/^repo: .*/repo: OpenMausBot/' "$d/linux-unpacked/resources/app-update.yml"
espera 1 "repo OpenMausBot falha" "repo operai-releases" "$script" linux "$d" v0.1.150

d="$(montar macos 0.1.150)"; rm -r "${d:?}/mac" "${d:?}/mac-arm64"
espera 1 "macos: nenhum app-update.yml falha" "Nenhum app-update.yml" "$script" macos "$d" v0.1.150

d="$(montar windows 0.1.150)"; echo "publisherName: Fulano" >> "$d/win-unpacked/resources/app-update.yml"
espera 1 "publisherName sem assinatura falha" "tem publisherName" "$script" windows "$d" v0.1.150

d="$(montar windows 0.1.150)"; mv "$d/OperaiBot-0.1.150-setup.exe" "$d/Operai Bot-0.1.150-setup.exe"
sed -i.bak 's/OperaiBot-0.1.150-setup.exe$/Operai Bot-0.1.150-setup.exe/' "$d/latest.yml"
espera 1 "nome com espaço (o GitHub renomearia o asset) falha" "caractere que o GitHub renomeia" "$script" windows "$d" v0.1.150

espera 1 "plataforma desconhecida falha" "Plataforma desconhecida" "$script" solaris "$(mktemp -d)" v0.1.150

if [ "$falhas" -gt 0 ]; then echo "$falhas teste(s) falharam"; exit 1; fi
echo "todos os testes passaram"
