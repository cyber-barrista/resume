## How to compile a resume

### Synopsis

* Get to the repo root
* Run `nix develop`
* Run `yarn install-tex-deps`
* Run `yarn build:resume`
* There it is, in the `dist` directory

## How to compile a cover letter

Since cover letters are unique per employer and position the compilation takes in a config `yaml` of a following schema

```yaml
title: [target position]
addresseeCompany: [target company]
addressee: [entity that will read the letter]
content: [content of the letter]
```
### Synopsis

* Get to the repo root
* Run `nix develop`
* Run `yarn install-tex-deps`
* Create a work directory `mkdir cover-letter-workdir` (naming matters)
* Create a config yaml file according to the schema and place it in `cover-letter-workdir` (say it's called `latter-sample.yaml`)
* Change you latter picture by replacing `cover-letter/picture.png` file with your own
* Run `yarn build:letter latter-sample`
* There it is, generated as `cover-letter-workdir/latter-sample.pdf`

## Currently deployed resume

[Deployed resume](https://cyber-barrista.github.io/resume/)
