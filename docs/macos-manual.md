# Ajustes manuais inevitáveis no macOS

Algumas áreas são protegidas por TCC, pelo Secure Enclave ou pela conta Apple.
O instalador não tenta contornar essas proteções.

## Segurança e conta

- Ative o FileVault em **Ajustes do Sistema → Privacidade e Segurança** e guarde
  a chave de recuperação fora do Mac.
- Cadastre Touch ID.
- Entre na Apple Account e escolha manualmente os dados do iCloud.
- Revise Find My Mac.

## Permissões

- Conceda Full Disk Access ao terminal usado com `sbedit` se a automação dos
  Favoritos do Finder não conseguir ler `FavoriteItems.sfl4`.
- Conceda Screen Recording ao SideScreen e ao RustDesk.
- Conceda Accessibility ao RustDesk somente se controle remoto for necessário.
- Revise notificações de Anki, FeedFlow, LocalSend e Syncthing.

O instalador nunca executa `xattr -cr`, nunca desabilita Gatekeeper e nunca
desabilita SIP.

## Finder

Se `sbedit` deixar de funcionar em uma versão futura do macOS, monte
manualmente esta ordem em Favoritos:

1. Applications
2. pasta pessoal
3. Developer
4. Downloads
5. Documents
6. Recents

## Aplicativos e dados

- Reassocie o dispositivo Syncthing; a identidade do dispositivo não pertence
  aos dotfiles.
- Restaure a vault do Obsidian, coleção do Anki e banco do KeePassXC a partir
  dos seus backups.
- Configure o perfil e a sincronização do Zen.
- Importe ambientes e volumes do OrbStack separadamente.

## Wallpapers

O instalador procura wallpapers em `~/Documents/wallpapers` no macOS e no
Arch. Mantenha a coleção pesada no Drive e sincronize-a para esse caminho.
Quando a pasta estiver vazia, o wallpaper fallback dos dotfiles será usado.

`WALLPAPER_DIR` pode substituir o caminho padrão sem ser versionada.
