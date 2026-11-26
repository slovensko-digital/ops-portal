# Contributing

## Find something to work on

Issues labelled [`good first issue`](https://github.com/slovensko-digital/ops-portal/labels/good%20first%20issue)
and [`help wanted`](https://github.com/slovensko-digital/ops-portal/labels/help%20wanted) are a good start. Comment
on the issue before you start so work isn't duplicated.

## Report a bug or suggest a feature

Open an [issue](https://github.com/slovensko-digital/ops-portal/issues/new). For a bug, include steps to reproduce,
what you expected and what happened.

Report security vulnerabilities privately through
[Report a vulnerability](https://github.com/slovensko-digital/ops-portal/security/advisories/new), not as an issue.

## Make a change

1. Fork the repository and create a branch in your fork, only maintainers can push to this one. In an existing
   clone, `gh repo fork --remote` adds your fork as `origin` and renames this repository to `upstream`.
2. Set up the app as described in [Run only the portal](README.md#run-only-the-portal), or
   [Run the stack locally](README.md#run-the-stack-locally) when your change touches Triage or a Backoffice.
3. Add or update tests at the level [docs/TESTING.md](docs/TESTING.md) describes. When you change a flow, update
   the matching file in [docs/how-it-works/](docs/how-it-works/README.md).
4. Run `bin/ci` and make sure it passes.

## Open a pull request

Open it from your fork against `main`, link the issue (`Closes #123`) and fill in the sections of the
[template](.github/pull_request_template.md). In Claude Code, `/dev:prepare-pr-for-review` writes the description
from it: the repo's `.claude/settings.json` offers the `dev` plugin from
[slovensko-digital/skills](https://github.com/slovensko-digital/skills) when you trust the folder.

A maintainer may need to approve the CI run on your first pull request.
