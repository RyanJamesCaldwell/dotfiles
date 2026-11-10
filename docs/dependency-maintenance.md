# Dependency maintenance

Dependabot checks GitHub Actions references weekly on Monday at 09:00
America/New_York. Minor and patch updates are grouped; major updates remain
separate. At most three version-update PRs are open at once.

Every update uses the existing macOS validation and Ubuntu bootstrap CI. This
configuration only opens PRs: it does not approve, merge, apply dotfiles to a
host, or change repository protection settings.

## What is not automated yet

- Neovim plugins are pinned in `dot_config/nvim/lazy-lock.json`. Dependabot does
  not update that lockfile. A future updater should open a dedicated lockfile PR,
  run isolated Neovim startup checks and validate the exact committed versions.
  Existing CI uses `Lazy! sync`, which may update the lockfile during validation;
  that is not yet proof that the committed plugin versions were tested.
- `Brewfile` names packages rather than pinning a reproducible set of versions.
  Broad host-level `brew upgrade` is not part of this automation.
- Linux release binaries and chezmoi externals need a reviewed version/checksum
  inventory before automated pin updates are safe and reproducible.

## Before unattended merge or host application

Require both CI jobs at the final PR commit. Keep changes to workflows,
installers, authentication, shell startup and host permissions under explicit
review. A later host-application step must check local drift, render into a
throwaway destination, preserve a known-good shell and retain recoverable
backups. Never apply this repository automatically to an active or work laptop
just because an update PR passed CI.
