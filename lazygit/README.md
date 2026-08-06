# lazygit

`config.yml` wires lazygit's file-opening into Microsoft Edit (`edit`) and
enables Nerd Font glyphs.

## Wiring

Lazygit defaults to `%LOCALAPPDATA%\lazygit\config.yml`, but honours
**`LG_CONFIG_FILE`** — so this file *is* the config, with no link and no copy.
Same escape hatch as [`../herdr/`](../herdr/README.md) (`HERDR_CONFIG_PATH`)
and [`../fresh/`](../fresh/README.md) (`--config`).

```powershell
# Run once per machine:
[Environment]::SetEnvironmentVariable(
    'LG_CONFIG_FILE', "$env:USERPROFILE\.glzr\lazygit\config.yml", 'User')
```

Restart the terminal so new lazygit processes see the variable.

Note: `state.yml` (window/UI state) stays in `%LOCALAPPDATA%\lazygit` —
lazygit writes it next to its default config dir regardless, and it's runtime
state, not configuration.
