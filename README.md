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

O install executa o equivalente a:

```sh
mkdir -p "$HOME/Documents/obsidian-vault" "$HOME/Documents/wallpapers"
```

Ele também semeia o banco local do zoxide com `~/Developer`,
`~/Documents/obsidian-vault` e `~/Documents/wallpapers`. O zsh inclui atalhos
estáveis para essas pastas:

```sh
dev
obsidian
wallpapers
```

O binário publicado do [mailghost](https://github.com/Kelvin-Jesus/mailghost)
também é instalado em `~/.local/bin` com versão e SHA-256 fixados.

## Scripts pessoais em Rust

O install compila e instala em `~/.local/bin`:

- `check_true_flac`: identifica FLACs reais pelo cabeçalho;
- `compress-video`: converte vídeos para HEVC usando `ffmpeg`;
- `is-avif`: encontra AVIFs com extensão incorreta e atualiza links do Obsidian;
- `pformat`: imprime o MIME type detectado pelo comando nativo `file`.

Todos aceitam `--dry-run`. Os comandos somente de leitura executam a inspeção
normal e confirmam que nenhuma alteração será feita. O build usa `CARGO_HOME` e
`CARGO_TARGET_DIR` temporários: crates e artefatos de compilação são apagados ao
final, permanecendo apenas os quatro binários. Nenhum comando instala pacotes
durante a execução. `compress-video` exige `ffmpeg` e `ffprobe` no `PATH`;
`pformat` exige `file`.

Exemplos:

```sh
is-avif --dry-run --rename --update-notes ~/Documents/obsidian-vault
compress-video --dry-run ~/Downloads/videos
check_true_flac --dry-run --relative ~/Music
pformat --dry-run ~/Downloads/archive.zip
```

## Comandos principais

```sh
./dotfiles preflight
./dotfiles install --dry-run
./dotfiles install
./dotfiles audit
./dotfiles security
./dotfiles doctor
./dotfiles test
./dotfiles update --dry-run
./dotfiles update
./dotfiles restore
./dotfiles uninstall --dry-run
```

`./dotfiles` é a interface principal, mas os scripts em `scripts/` continuam
podendo ser executados diretamente.

O preflight compara todos os destinos Stow sem alterar arquivos. Um install
normal para ao encontrar conflitos. Para preservar e substituir os conflitos
explicitamente:

```sh
./dotfiles install --backup-conflicts
```

Os arquivos são movidos para
`~/.local/state/dotfiles/backups/stow/<timestamp>/`, mantendo o caminho relativo
ao `$HOME`.

`./dotfiles audit` é somente leitura: compara pacotes declarados, links Stow,
configurações não gerenciadas, estado do Git e o doctor. Ele nunca copia
configurações locais para o repositório. `./dotfiles security` procura nomes de
arquivos sensíveis, tokens, atribuições de segredos e chaves privadas sem
imprimir os possíveis valores. Antes de um commit, use:

```sh
./dotfiles security --staged
```

O instalador nunca usa `stow --adopt`. Arquivos conflitantes fazem a etapa
falhar, salvo quando `--backup-conflicts` é fornecido explicitamente.

`update.sh` atualiza pacotes, runtimes, LazyVim e plugins do tmux. A
desinstalação remove apenas links e integrações gerenciadas; pacotes, dados,
repositório e shell de login são preservados. No macOS, `--restore-settings`
também restaura o backup mais recente.

Consulte [docs/migration-checklist.md](docs/migration-checklist.md) para o
rollout e [docs/macos-manual.md](docs/macos-manual.md) para ajustes que o macOS
não permite automatizar com segurança.
