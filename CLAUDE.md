# CLAUDE.md

## Releases are automated — keep them working

This repo is versioned and released by **release-please**, through the shared workflow
`Gravitas-Security/DevSecOps-pipelines/.github/workflows/release_please.yaml`
(called from `.github/workflows/release-please.yaml`). On every push to `main` it reads
the new commits, opens a release PR, merges it and tags `vX.Y.Z`.

**Commit messages and PR titles must be Conventional Commits:** `type(scope)!: summary`

| Type | Release |
|---|---|
| `fix:` | patch |
| `feat:` | minor |
| `!` after the type (`feat!:`), or a `BREAKING CHANGE:` footer | major |
| `chore:` `ci:` `docs:` `refactor:` `test:` `build:` `style:` `perf:` | none |

- Use `fix:` or `feat:` for any change consumers should get; otherwise nothing is released.
- Mark removed or renamed variables, outputs or resources as breaking (`!`).
- **Squash-merge PRs.** The PR title becomes the commit on `main`, so it must be conventional.
  Merge commits ("Merge pull request #…") are ignored by release-please.
- Don't edit `CHANGELOG.md` or version numbers, and don't create tags or GitHub releases by
  hand. release-please owns them.
- Don't edit release PRs (`chore(main): release x.y.z`); they merge themselves.
- Keep `.github/workflows/release-please.yaml` a thin caller. Change release behaviour in
  DevSecOps-pipelines, which affects every module repo.
- Consumers pin a tag (`?ref=vX.Y.Z`). After a release, bump the ref where the module is used.
- This repo holds several modules that share **one** version. Consumers pin a module as
  `github.com/Gravitas-Security/<repo>//<module-dir>?ref=vX.Y.Z`; a release
  bumps every module's tag, so say which module changed in the scope (`fix(aws-vpc): …`).
