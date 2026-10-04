# resume

A LaTeX resume and cover letters, built by Nix, published on GitHub Pages through a general-purpose PDF viewer.

## Architecture: dendritic pattern

The flake follows the [dendritic pattern](https://github.com/mightyiam/dendritic): flake-parts + import-tree,
one file per feature.

- `flake.nix` declares inputs and evaluates flake-parts with `import-tree ./modules` — every `.nix` file under
  `modules/` is a flake-parts module, auto-imported. There are **no import lists**; adding a feature = dropping a file.
- Shared values are typed `perSystem` options declared by the module that owns them (`config.tex.*` in `tex.nix`,
  `config.node.*` in `node.nix`, `config.pdfRenderer` in `renderer/`), read lexically by the feature files.
  Never thread them through `specialArgs`.
- **Assets live next to their module** (`resume/*.tex`, `cover-letter/template.tex`, the whole web app under
  `renderer/`), so a feature is deletable as a unit.
- **No `enable` options.** An imported module is on; deleting the file is the off switch.
- **Comments carry the why**, including hard-won constraints (see the EmbedPDF notes below). Preserve them when
  moving code.
- `nix fmt` (nixfmt-tree, RFC 166 style) before considering work done.

## Layout

| Path | Owns |
|---|---|
| `modules/tex.nix` | `tex.texlive`, `tex.deps` (awesome-cv + dracula, pinned by hash), `tex.env` (fonts, `TEXINPUTS`) |
| `modules/node.nix` | `node.nodejs`, `node.pnpm` (nixpkgs' pnpm; asserts `renderer/package.json`'s `packageManager` matches) |
| `modules/resume/` | `packages.resume`: the PDF itself (not a directory), from `resume.tex` + section files |
| `modules/cover-letter/` | `packages.cover-letter`: shell CLI (yq + xelatex) filling `template.tex` from a YAML |
| `modules/renderer/` | `packages.pdf-renderer` (the PDF-agnostic app) and `pdfRenderer { pdf, fileName, downloadName, title }` → static site (also `legacyPackages.pdfRenderer` for other flakes); `checks.renderer`; the Vite app, `pnpm-lock.yaml`, `pnpm-workspace.yaml` (pnpm settings) |
| `modules/site.nix` | `packages.site` = `pdfRenderer { pdf = packages.resume; ... }` with the resume's names, also `packages.default` |
| `modules/dev-shell.nix` | `nix develop`: TeX + Node toolchains with `tex.env` exported |
| `.github/workflows/site.yml` | `nix flake check`; on `main`, `nix build .#site` and deploy to GitHub Pages — skipped when the live site already has this build (see Deploy) |
| `renovate.json` | root on purpose: repo-level infra |

## Toolchain

- Run every tool through the dev shell: `nix develop -c ...`. The flake pins Node, pnpm and TeX; when a version
  drifts, bump the flake instead of using a global binary. `node.nix` asserts that `packageManager` in
  `renderer/package.json` matches nixpkgs' pnpm, so a nixpkgs bump that moves pnpm means updating that field too.
- Pin dependencies to exact versions (`pnpm add --save-exact`); Renovate runs with `rangeStrategy: pin` and opens
  one grouped PR a month (npm packages and GitHub Actions; `flake.lock` and the TeX pins are manual). It is told to
  leave `packageManager` alone (pnpm follows nixpkgs) and to keep `@types/node` on Node's major. A Renovate PR that
  changes `pnpm-lock.yaml` needs the `fetchPnpmDeps` hash refreshed before it can go green.
- No git hooks (no husky): `nix flake check` and CI run format, lint and typecheck (`pnpm format:check`, `pnpm lint`,
  `pnpm typecheck` in the dev shell).
- **Flakes only see git-tracked files.** `git add` new files before `nix build`, or nix reports them missing.
- **After changing npm dependencies**, update the `fetchPnpmDeps` hash in `renderer/default.nix`: set it to `""`,
  build, copy the hash from the mismatch error. One hash covers every system because pnpm's lockfile has an integrity
  hash for every package and `supportedArchitectures` in `renderer/pnpm-workspace.yaml` makes every install fetch the
  binaries for exactly the flake's four systems (so a local `pnpm install` also brings the Linux ones, ~1 GB store).
  Do not let the fetcher's default `--force` back in: it pulls every platform on npm (~2 GB) — `--no-force` wins.
- **Node stays on 26** (`node.nix`): with nixpkgs' node 24.15 a fresh `pnpm install` on macOS dies with SIGKILL
  (EXC_GUARD, a double-closed file descriptor in pnpm's extraction).
- TeX documents resolve the class and theme through `TEXINPUTS` (`tex.env`), not `\input@path`; the dev shell exports
  it, so `xelatex modules/resume/resume.tex` works from anywhere.

| Task | Command |
|---|---|
| Resume PDF | `nix build .#resume` |
| Cover letter | `nix run .#cover-letter -- letter.yaml [out.pdf]` |
| Site | `nix build .#site` (`result/index.html`); the bare app: `nix build .#pdf-renderer` |
| Checks (format, lint, typecheck in a sandbox) | `nix flake check` |
| Renderer dev loop | `cd modules/renderer`, any PDF at `public/document.pdf`, `pnpm dev` |
| Format Nix | `nix fmt` |

## Deploy (GitHub Pages)

- `.github/workflows/site.yml` computes the site's **nix store path by pure `nix eval`** (no build), compares its
  hash with the `build-id.txt` the previous deploy left next to `index.html`, and only builds and deploys when they
  differ — doc/CI edits are no-ops. Any curl failure fails open (deploys). `workflow_dispatch` has a `force` input
  to redeploy an unchanged build (after a Pages settings change, say).
- The skip relies on the filesets in `modules/`: `resume/` takes only `*.tex`, `renderer/` excludes its
  `default.nix` and local build output. A new build input belongs in those filesets, not next to them.
- `build-id.txt` is written by CI, deliberately outside the derivation (deploy metadata, not site content).
- Actions are pinned to exact release tags — or, where an action only publishes moving major tags
  (`DeterminateSystems/nix-installer-action`), to the commit SHA with the version in a trailing comment, which
  Renovate understands and bumps. Bump them deliberately.
- One-time prerequisite still pending: switch the repository's Pages source from the `main` branch to
  GitHub Actions (Settings → Pages), or the deploy job fails.

## Code style (renderer)

Shared with handy-surf:

- **Imports**: absolute from `src/` (`import Toolbar from 'src/ui/toolbar/toolbar'`), extensionless. Relative imports are lint
  errors outside the root config files. Biome orders them: packages, a blank line, then `src/...`.
- **Files**: kebab-case. One component per folder under `src/ui/<component>/`, with its styles next to it as
  `<component>.module.css`. Global reset and the colour/shadow custom properties live in `src/styles/styles.css`.
- **Components**: arrow functions typed `React.FC<Props>`, `type Props` (never `interface`), default export at the end.
- **Layers**: `*-data-layer.tsx` reads EmbedPDF capabilities and hands plain values and callbacks down (memoised so
  they stay stable); `*-logic-layer.tsx` owns state, effects and handlers; `<component>.tsx` is presentation only,
  props in, no hooks. Skip a layer when it has nothing to do; import the outermost layer.
- **Types**: strict, no `any`, explicit return types on every function, including inline JSX callbacks
  (`onClick={(): void => ...}`); index access returns `T | undefined`, so check it.

## Renderer contract

- The app reads the document from `#root`'s `data-pdf` (URL) and `data-download-name` attributes and the page
  `<title>`; `index.html` carries the defaults `./document.pdf` / `document.pdf` / `PDF`, and `pdfRenderer`
  rewrites exactly those strings (`substituteInPlace --replace-fail`), so changing them means changing both.
- Vite handles no PDF at all: nothing in `src/` or `vite.config.ts` may know the document, its name or its origin.

## EmbedPDF notes

- The PDFium wasm is self-hosted (`?url` import) and the font fallback is off; nothing loads from a CDN.
- Pages render as whole images at zoom × devicePixelRatio. Do not add tiling: zoom is capped at a 1024px-wide page,
  and tiling's low-resolution base layer made the text visibly blurry while tiles loaded.
- The fullscreen and print plugins mount their own wrapper/frame; do not add another `FullscreenProvider`.
- Selection has no copy keybinding and search does not scroll to matches; `copy-shortcut` and `search-bar` do both.
- Link annotations render as clickable `<div>`s (`window.open`), not `<a>` tags; a real link layer only exists in
  EmbedPDF's unreleased 3.0 line.
