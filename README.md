# Dotfiles

Bootstrap idempotente para macOS e Arch Linux usando GNU Stow. O repositório
instala as ferramentas, aplica as configurações compartilhadas e configura as
preferências reproduzíveis do macOS.

Não fazem parte deste repositório: credenciais do GitHub, perfis de navegador,
vault do Obsidian, coleção do Anki, banco do KeePassXC, identidades do
Syncthing, projetos e wallpapers pesados.

## macOS novo

Execute primeiro o bootstrap usando apenas ferramentas nativas:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Kelvin-Jesus/dotfiles/main/bootstrap.sh)"
```

As Command Line Tools da Apple exigem confirmação interativa. Se o bootstrap
iniciar essa instalação, conclua-a e execute o mesmo comando novamente.

Para incluir SideScreen e SpotiFLAC, que não possuem cask oficial:

```sh
~/dotfiles/install.sh --with-optional-apps
```

Esses aplicativos usam releases e SHA-256 fixados. O instalador não remove
quarentena nem contorna o Gatekeeper.

## Arch Linux

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Kelvin-Jesus/dotfiles/main/bootstrap.sh)"
```

O bootstrap instala `base-devel`, Git e Stow com `pacman`, compila `yay` como
usuário normal e entrega o restante da instalação ao `yay`.

## Comandos principais

```sh
./install.sh --dry-run
./install.sh
./scripts/sandbox.sh
./scripts/doctor.sh
./scripts/macos/remove-native-apps.sh
```

O instalador nunca usa `stow --adopt`. Arquivos conflitantes fazem a etapa
falhar para evitar sobrescrever dados locais.

Consulte [docs/migration-checklist.md](docs/migration-checklist.md) para o
rollout e [docs/macos-manual.md](docs/macos-manual.md) para ajustes que o macOS
não permite automatizar com segurança.
