# Checklist de migração

## Antes de trocar de Mac

1. Revise `git status` e o diff desta branch.
2. Execute `./scripts/sandbox.sh`.
3. Faça commit, merge em `main` e push para o GitHub.
4. Confirme backups externos:
   - KeePassXC;
   - Obsidian;
   - Anki;
   - chaves SSH/GPG;
   - Syncthing;
   - projetos;
   - wallpapers;
   - dados do OrbStack.
5. O projeto `mailsy-rs` deve ficar em `~/Documents` ou `~/Developer`, com
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

Para configurar os login items:

```sh
~/dotfiles/install.sh --skip-packages --skip-runtimes --skip-editors --with-login-items
```

## Verificação

```sh
cd ~/dotfiles
./install.sh --dry-run --with-optional-apps
./scripts/test-stow.sh
./scripts/macos/apply.sh --dry-run
./scripts/doctor.sh
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
