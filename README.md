# Operaí Releases

Repositório público que builda o app desktop Operaí e publica os instaladores nas Releases. **Não há código aqui**: só o workflow (`.github/workflows/release.yml`) e um script de apoio. O código-fonte está em repositórios privados (`PedroPCardoso/operai-desktop` e `PedroPCardoso/operai`, pasta `router/`), lidos pelo workflow com deploy keys somente leitura guardadas como secrets do environment `release`.

## Como disparar

O workflow só roda à mão (`workflow_dispatch`). Antes, a tag `vX.Y.Z` precisa existir no `operai-desktop` e bater com a `version` do `package.json` daquele commit.

```
scripts/disparar.sh v0.1.142              # release em rascunho (draft)
scripts/disparar.sh v0.1.142 --publicar   # release publicada
scripts/disparar.sh v0.1.142 --publicar <commit-ou-branch-do-roteador>
```

Ou pela aba Actions, workflow "Release do Operaí", com os campos `tag`, `operai_ref` (padrão `main`) e `publicar` (padrão desmarcado).

## Como aprovar

Cada job de build (Windows, macOS, Linux) usa o environment `release`, que exige aprovação do Pedro. Na página da execução, clique em "Review deployments", marque `release` e aprove (um pedido por job). Sem aprovação, nada builda e nenhum secret é lido.

## O que vai na release

Só instaladores e o feed de atualização, nunca código-fonte:

- Windows: `OperaiBot-<versão>-setup.exe` (NSIS), o `.blockmap` dele e `latest.yml`
- macOS: `.dmg` e `.zip` (arm64 e x64), os `.blockmap` e `latest-mac.yml`
- Linux: `.AppImage`, `.deb` e `latest-linux.yml`

Sem `publicar`, a release fica em rascunho; confira e publique pela página de Releases. Os jobs falham se a versão do `package.json` não bater com a tag, se o pacote não contiver o roteador ou se o feed estiver errado (`scripts/conferir-feed.sh`: `latest*.yml` ausente, arquivo citado que não existe, versão diferente da tag, `app-update.yml` que não aponta para este repositório ou com `publisherName`).

## Atualização automática

O app lê os `latest*.yml` da release **publicada** mais recente deste repositório (repositório público: nenhum token no app). Publicar a release é o que libera a versão para quem já tem o app; rascunho não aparece. No Windows e no Linux o app baixa em segundo plano e instala quando a pessoa clica em "Reiniciar para atualizar" ou fecha o app. No Mac o app só avisa e abre esta página: sem assinatura, o macOS não deixa o app se atualizar sozinho.

O updater não desce de versão. Para voltar atrás, publique um número maior com o build bom.

Testes do script de conferência: `tests/conferir-feed.test.sh`.

## Ainda não existe

Assinatura (Windows e macOS) e notarização. Por isso o Windows e o macOS avisam na primeira abertura, e o Mac não se atualiza sozinho. O plano está na spec do PR #114 do `operai-desktop`.
