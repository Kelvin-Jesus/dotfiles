# Checklist de migração

## Antes de trocar de Mac

1. Revise `git status` e o diff desta branch.
2. Execute `./dotfiles security` e `./dotfiles audit`.
3. Execute `./dotfiles test`.
4. Faça commit, merge em `main` e push para o GitHub.
5. Confirme backups externos:
   - KeePassXC;
   - Obsidian;
   - Anki;
   - chaves SSH/GPG;
   - Syncthing;
   - projetos;
   - wallpapers;
   - dados do OrbStack.
5. O projeto `mailghost` deve ficar em `~/Documents` ou `~/Developer`, com
   repositório Git próprio; ele não pertence aos dotfiles.

## Primeiro bootstrap

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Kelvin-Jesus/dotfiles/main/bootstrap.sh)"
```

Se as Command Line Tools forem abertas, conclua a instalação e repita o
comando.

Para instalar também SideScreen e SpotiFLAC:

```sh
~/dotfiles/install.sh --with-optional-apps
```

## Verificação

```sh
cd ~/dotfiles
./dotfiles preflight
./dotfiles install --dry-run --with-optional-apps
./dotfiles test
./dotfiles settings --dry-run
./dotfiles doctor
```

Abra um terminal novo e confirme:

- Fastfetch aparece apenas uma vez e não em cada pane do tmux;
- Starship e os ícones Nerd Font funcionam;
- `ping` executa `gping`;
- `ping-native` executa o ping original;
- LazyVim abre sem referências ao AstroNvim;
- `Caps Lock` produz Escape;
- Finder, Dock e Favoritos têm a ordem esperada.

Execute o instalador pela segunda vez para confirmar idempotência.

## Recuperação dos dados que não pertencem aos dotfiles

Antes de apagar ou entregar a máquina antiga, confirme cada item:

- [ ] **Projetos:** todos os repositórios têm remoto, `git status` revisado e
      commits enviados; projetos sem Git possuem backup externo.
- [ ] **SSH/GPG:** chaves necessárias estão em backup criptografado; permissões
      e autenticação foram testadas no Mac novo.
- [ ] **KeePassXC:** banco e eventual key file foram copiados separadamente e o
      banco abre no Mac novo.
- [ ] **Obsidian:** vault, anexos, plugins e snippets foram sincronizados e uma
      nota foi editada para testar escrita; execute
      `~/dotfiles/scripts/install-obsidian-fonts.sh` depois da primeira
      sincronização para instalar as fontes portáteis no macOS e Android.
- [ ] **Anki:** coleção e mídia foram sincronizadas ou exportadas e abertas no
      Mac novo.
- [ ] **Zen:** perfil, favoritos, extensões e códigos de recuperação foram
      restaurados.
- [ ] **Syncthing:** o Mac novo foi pareado como novo dispositivo e todas as
      pastas mostram estado sincronizado.
- [ ] **OrbStack:** máquinas, imagens, volumes e dados persistentes necessários
      foram exportados e validados separadamente.
- [ ] **Wallpapers:** a coleção está no Drive e sincronizada em
      `~/Documents/wallpapers`.
- [ ] **Apple Account:** iCloud, Find My Mac, FileVault e a chave de recuperação
      foram revisados manualmente.

## Remoção opcional de aplicativos Apple

Primeiro revise o dry-run:

```sh
./scripts/macos/remove-native-apps.sh
```

Somente depois:

```sh
./scripts/macos/remove-native-apps.sh --apply
```

O script aceita apenas GarageBand, iMovie, Pages, Numbers e Keynote em
`/Applications`; nada em `/System/Applications` é removido.
