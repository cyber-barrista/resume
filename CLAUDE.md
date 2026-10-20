# resume

A LaTeX resume and cover letters, built by Nix, published on GitHub Pages through a general-purpose PDF viewer.

## Architecture: dendritic pattern

The flake follows the [dendritic pattern](https://github.com/mightyiam/dendritic): flake-parts + import-tree,
one file per feature.

- `flake.nix` declares inputs and evaluates flake-parts with `import-tree ./modules` — every `.nix` file under
  `modules/` is a flake-parts module, auto-imported. There are **no import lists**; adding a feature = dropping a file.
- Shared values are typed `perSystem` options declared by the module that owns them (`config.tex.*` in `tex/`,
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
| `modules/tex/` | `tex.texlive`, `tex.deps` (awesome-cv, patched for the text layer, + dracula, pinned by hash), `tex.env` (`OSFONTDIR`, `TEXINPUTS`) |
| `modules/node.nix` | `node.nodejs`, `node.pnpm` (nixpkgs' pnpm; `renderer/package.json` has no `packageManager` on purpose) |
| `modules/resume/` | `packages.resume`: the PDF itself (not a directory), from `resume.tex` + section files; `parser-only.tex`: text only parsers see (see Resume checks) |
| `modules/cover-letter/` | `packages.cover-letter`: shell CLI (yq + lualatex) filling `template.tex` from a YAML |
| `modules/renderer/` | `packages.pdf-renderer` (the PDF-agnostic app) and `pdfRenderer { pdf, fileName, downloadName, title }` → static site (also `legacyPackages.pdfRenderer` for other flakes); `checks.renderer`; the Vite app, `pnpm-lock.yaml`, `pnpm-workspace.yaml` (pnpm settings) |
| `modules/site.nix` | `packages.site` = `pdfRenderer { pdf = packages.resume; ... }` with the resume's names, also `packages.default` |
| `modules/resume-checks/` | checks on the built PDF (see Resume checks): `checks.vale` and `checks.languagetool` (`prose.nix`, `vale.ini`, `vocabulary.txt`), `checks.openresume` (`openresume/`: OpenResume's parser against `expected.json`) |
| `modules/dev-shell.nix` | `nix develop`: TeX + Node toolchains with `tex.env` exported |
| `.github/workflows/pr.yml` | every PR: `nix flake check` and a `nix build .#site` that proves the site builds |
| `.github/workflows/main.yml` | pushes to `main`: build and deploy to GitHub Pages, skipped when the live site already has this build (see Deploy) |
| `renovate.json` | root on purpose: repo-level infra |

## Toolchain

- Run every tool through the dev shell: `nix develop -c ...`. The flake pins Node, pnpm and TeX; when a version
  drifts, bump the flake instead of using a global binary. pnpm's version is nixpkgs' alone: `renderer/package.json`
  carries no `packageManager` field, so neither corepack nor Renovate has anything to pin, and `pnpm-workspace.yaml`
  sets `minimumReleaseAge: 0` (pnpm 11 would otherwise reject packages younger than a day at build time).
- Pin dependencies to exact versions (`pnpm add --save-exact`); Renovate runs with `rangeStrategy: pin` and opens
  one grouped PR a month: npm packages, GitHub Actions and, with the `nix` manager enabled, the `flake.lock` inputs
  (the TeX pins are manual). It is told to keep `@types/node` on Node's major. A Renovate PR that changes
  `pnpm-lock.yaml` or moves nixpkgs' pnpm needs the `fetchPnpmDeps` hash refreshed before it can go green.
- No git hooks (no husky): `nix flake check` and CI run format, lint and typecheck (`pnpm format:check`, `pnpm lint`,
  `pnpm typecheck` in the dev shell), and the resume checks.
- **Flakes only see git-tracked files.** `git add` new files before `nix build`, or nix reports them missing.
- **After changing npm dependencies**, update the `fetchPnpmDeps` hash in `renderer/default.nix`: set it to `""`,
  build, copy the hash from the mismatch error. One hash covers every system because pnpm's lockfile has an integrity
  hash for every package and `supportedArchitectures` in `renderer/pnpm-workspace.yaml` makes every install fetch the
  binaries for exactly the flake's four systems (so a local `pnpm install` also brings the Linux ones, ~1 GB store).
  Do not let the fetcher's default `--force` back in: it pulls every platform on npm (~2 GB) — `--no-force` wins.
- **Node stays on 26** (`node.nix`): with nixpkgs' node 24.15 a fresh `pnpm install` on macOS dies with SIGKILL
  (EXC_GUARD, a double-closed file descriptor in pnpm's extraction).
- TeX documents resolve the class and theme through `TEXINPUTS` (`tex.env`), not `\input@path`; the dev shell exports
  it, so `lualatex modules/resume/resume.tex` works from anywhere. luaotfload, which does not read fontconfig, finds
  Source Sans 3 through `OSFONTDIR` (texlive has only the older Source Sans Pro) and caches font names under `HOME`.

| Task | Command |
|---|---|
| Resume PDF | `nix build .#resume` |
| Cover letter | `nix run .#cover-letter -- letter.yaml [out.pdf]` |
| Site | `nix build .#site` (`result/index.html`); the bare app: `nix build .#pdf-renderer` |
| Checks, sandboxed (renderer format, lint, typecheck; resume checks) | `nix flake check` |
| One check and its findings | `nix build .#checks.aarch64-darwin.vale -L` (or `languagetool`, `openresume`, `renderer`) |
| Renderer dev loop | `cd modules/renderer`, any PDF at `public/document.pdf`, `pnpm dev` |
| Format Nix | `nix fmt` |

## Deploy (GitHub Pages)

- `.github/workflows/pr.yml` verifies pull requests (checks + site build, nothing kept); `.github/workflows/main.yml`
  deploys: it computes the site's **nix store path by pure `nix eval`** (no build), compares its
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

## Text layer

What a PDF extracts as (parsers, search, copy-paste) is not what it shows, and both documents are judged on it. It is
set up by configuration only; keep it that way.

- **LuaLaTeX, not XeLaTeX.** XeLaTeX (xdvipdfmx) extracts Source Sans 3's hyphen as U+2011 and small caps as capitals
  with a stray lowercase i ("ENGiNEER"), with no TeX-level control: `\XeTeXgenerateactualtext` only helps poppler,
  while pdf.js ignores ActualText and loses the spaces between words.
- **luaotfload's node mode for text, HarfBuzz for small caps** (`tex.deps` patches awesome-cv's
  `Renderer=HarfBuzz` to `Renderer=Node, SmallCapsFeatures={Renderer=HarfBuzz}`). Node mode extracts hyphens as "-"
  but small caps as capitals ("SOFTWARE ENGINEER"); HarfBuzz mode extracts small caps in the case they were typed but
  a typed "-" as a soft hyphen. So a hyphen inside small caps (subsection titles, entry positions, the header's
  position line, the footer) is typed as U+2011 ("Non‑tech"), which HarfBuzz keeps.
- **Header icons extract as characters** (the envelope as an emoji). pdf.js puts a space between icon and email, but
  OpenResume drops it and reads "🖂cyber.barrista@gmail.com", so `parser-only.tex` also carries the email.
- LuaTeX dates `\today` by `SOURCE_DATE_EPOCH`, which stdenv and `nix develop` pin to 1980: the builds unset it.
- `resume.tex` never breaks a line at a typed hyphen (`\exhyphenpenalty`): extractors cannot tell it from TeX's own
  hyphenation, so "well-" at a line end comes out as "wellrounded" or "well- rounded". It keeps every `\cvsection`
  heading with its first lines (`needspace`): a stranded heading has the page footer between it and its section in
  reading order.
- Typography that extracts right: ``` ``…'' ``` for quotes, `--` for ranges (dates).

## Resume checks

- They read the built PDF, not the `.tex` sources: what TeX produces (quote marks, small caps, the class's header and
  footer) is what a reader or an ATS gets. `main.yml` runs `nix flake check` before deploying, so a failing resume
  check blocks the deploy.
- Vale fails on error-level alerts only (warnings and suggestions are printed); LanguageTool (LTeX+'s CLI) fails on
  any finding; OpenResume fails on any `expected.json` string it parses differently (case-insensitive).
- Content meant for parsers and not readers goes in `modules/resume/parser-only.tex`, never in the visible sections:
  invisible text (PDF rendering mode 3), placed through the `shipout/background` hook so the rendered pages stay
  pixel-identical and it comes first in each page's content stream. It holds the name on every page and the LinkedIn
  URL and email on the first; its comments say why each is needed.
- `vocabulary.txt` feeds both Vale and LanguageTool, and takes only correctly spelled words: listing a word makes Vale
  flag its other casings (`Vale.Terms`), and LanguageTool's dictionary is case-sensitive.
- OpenResume is AGPL-3.0, so it is fetched at build time, never vendored; it is unmaintained since 2024-10. Its one
  runtime dependency, `pdfjs-dist`, is the single npm tarball its lockfile resolves (no lockfile here), and
  `@reduxjs/toolkit` is stubbed. One parser's heuristics, not a real ATS: section titles must be bold uppercase or
  contain a keyword (experience, education, skill, ...), job titles must contain a listed word in its exact case
  ("Engineer"), locations must be a US "City, ST" (so `expected.json` has none), and pages are joined with no line
  break.

## Code style (renderer)

Shared with handy-surf:

- **Imports**: absolute from `src/` (`import Toolbar from 'src/ui/toolbar/toolbar'`), extensionless. Relative imports are lint
  errors outside the root config files. Biome orders them: packages, a blank line, then `src/...`.
- **Files**: kebab-case. One component per folder under `src/ui/<component>/`, with its styles next to it as
  `<component>.module.css`. Global reset and the colour/shadow custom properties live in `src/styles/styles.css`.
- **Components**: arrow functions typed `React.FC<Props>`, `type Props` (never `interface`), default export at the end.
- **Layers**: `*-data-layer.tsx` reads EmbedPDF capabilities and hands plain values and callbacks down;
  `*-logic-layer.tsx` owns state, effects and handlers; `<component>.tsx` is presentation only, props in, no hooks.
  Skip a layer when it has nothing to do; import the outermost layer.
- **No `useMemo`/`useCallback`**: the React Compiler (`oxc-transform-react`, the Rust port, enabled in
  `vite.config.ts` with `logDiagnostics`) memoises values and callbacks on their inputs, which is what keeps effect
  dependencies stable. A diagnostic in the build output means a component broke the Rules of React and lost that;
  fix the component rather than adding manual memoisation.
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
