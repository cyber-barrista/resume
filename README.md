## Currently deployed resume

[Deployed resume](https://cyber-barrista.github.io/resume/)

Everything is built by Nix. The flake has three modules (see `modules/`):

| Module | Output | Command |
|---|---|---|
| `resume` | the resume PDF | `nix build .#resume` → `result` is the PDF |
| `cover-letter` | a CLI that turns a YAML into a cover letter PDF | `nix run .#cover-letter -- letter.yaml` |
| `pdfRenderer` | a function from any PDF to a static web site showing it | `nix build .#site` (the resume rendered) |

Every PR runs the checks and builds the site; every push to `main` builds `.#site` and deploys it to GitHub Pages. Other flakes can render their own PDF with
`inputs.resume.legacyPackages.${system}.pdfRenderer { pdf = <PDF file or derivation>; fileName = ...; downloadName = ...; title = ...; }`;
the app itself (`nix build .#pdf-renderer`) is PDF-agnostic and reads the document from `data-*` attributes in
its `index.html`.

## How to compile the resume

* Get to the repo root
* Run `nix build .#resume`
* There it is: `result` (a symlink to the PDF)

## How to compile a cover letter

Since cover letters are unique per employer and position, the CLI takes a config `yaml` of the following schema.
Values are inserted into the LaTeX template verbatim, so they may contain TeX (`\textbf{...}`, `\\`, blank lines for
paragraphs):

```yaml
title: [target position]
addresseeCompany: [target company]
addressee: [entity that will read the letter]
content: [content of the letter]
```

* Create the yaml, say `letter.yaml`
* Run `nix run .#cover-letter -- letter.yaml` (an optional second argument names the output file)
* There it is, `letter.pdf` next to the yaml
* To change the picture, replace `modules/cover-letter/profile.png`

## How to work on the site

The viewer is a Vite + React app in `modules/renderer`; it shows whatever PDF `index.html` points at.

* Get to the repo root
* Run `nix develop`
* `cd modules/renderer`
* Run `pnpm install` (it fetches the native binaries for all four systems the flake builds for, so the first install
  is about 1 GB)
* Put a PDF at `public/document.pdf` for the dev server, e.g.
  `ln -sf "$(nix build ../..#resume --no-link --print-out-paths)" public/document.pdf`
* Run `pnpm dev` for a dev server with hot reload, or `pnpm build` for a static build in `dist` followed by
  `pnpm preview` to serve it (http://localhost:4173)
* Before pushing, run `pnpm format:check`, `pnpm lint` and `pnpm typecheck`; `nix flake check` runs the same in a
  sandbox, and so does CI. Code conventions are in `CLAUDE.md`
* After changing dependencies, update the `fetchPnpmDeps` hash in `modules/renderer/default.nix` (set it to `""`,
  build, copy the hash from the error)
