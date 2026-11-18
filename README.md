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

Só instaladores, nunca código-fonte:

- Windows: `OperaiBot-<versão>-x64-setup.exe` (NSIS)
- macOS: `.dmg` e `.zip` (arm64 e x64)
- Linux: `.AppImage` e `.deb`

Sem `publicar`, a release fica em rascunho; confira e publique pela página de Releases. Os jobs falham se a versão do `package.json` não bater com a tag ou se o pacote não contiver o roteador.

## Ainda não existe

Assinatura (Windows e macOS), notarização e feed de atualização automática. Por isso o Windows e o macOS avisam na primeira abertura. O plano está na spec do PR #114 do `operai-desktop`.
