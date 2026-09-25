---
name: prepare-pr-for-review
description: Prepare a pull request for review on GitHub with a description structured as "The problem" and "Solution", filled in from the branch diff, commits and linked issue, using the repo's PR template. Use this whenever the user wants to open, create, submit, publish or "make" a PR, says the branch is ready for review, asks to push and open a PR, or wants an existing PR's title or description written, rewritten or updated. Trigger even if the user does not mention the description itself; the structured description is the point.
---

# Prepare PR for review

Open (or update) a GitHub pull request whose description tells a reviewer two things
clearly: what problem existed, and how this branch solves it. Reviewers in this repo
read the description before the diff, so a body that is just an issue link or a
screenshot forces them to reverse-engineer intent from code. The two sections fix that.

The body always follows `.github/pull_request_template.md`. Read it first: it is the
source of truth for section names and hints, and it keeps PRs opened from the GitHub UI
and PRs opened by this skill identical in shape.

## Workflow

### 1. Understand the change

Gather evidence before writing a word:

```bash
git status --short
git branch --show-current
git log --oneline main..HEAD
git diff main...HEAD --stat
git diff main...HEAD
```

Read the full diff, not just the stat. Then find the linked issue:

- Look in commit messages, the branch name, and the conversation for `#123`,
  `closes #123`, or an issue URL.
- Issues for this project may live in a different repository than the code
  (e.g. `slovensko-digital/ops`). When you have a URL, view it with
  `gh issue view <number> -R <owner>/<repo>`; when you have only a bare `#123`,
  check the current repo first, then the issue repo used in recent PRs
  (`gh pr list --state merged --limit 5 --json body`).
- Pull the issue title and body into your understanding of the problem. The issue
  usually states the problem better than the diff does.

If there is no issue and the conversation does not explain the motivation, ask the user
one concrete question about what prompted the change. Do not invent a problem.

### 2. Make sure the branch is publishable

- If the current branch is `main`, stop and create a feature branch first; ask the user
  for a name only if nothing sensible follows from the change.
- Uncommitted changes: ask whether they belong in this PR before committing them.
- Push with `git push -u origin <branch>` if the branch has no upstream or is behind.

### 3. Write the title

One line, imperative, under about 70 characters, describing the outcome rather than
the mechanics. Use a `fix:` / `feat:` style prefix when the repo's recent commits do.
Put issue-closing keywords in the body, not the title; GitHub only honours them there.

Good: `fix: resolve issue immediately when the author marks it as resolved`
Weak: `changes to issues controller`

### 4. Write the body

Fill the template sections. Match the language the user is writing in during the
conversation; default to English.

**The problem.** Describe the situation before this PR from the perspective of the
person affected: what they do, what happens, what they expected, and why it matters.
Start with the issue link (`Closes #123` or the full URL) so it auto-closes on merge.
Two to five sentences is typical. Avoid describing the code here; "the callback set the
wrong state" is a cause, not a problem. "When an author marks their own issue as
resolved, it only shows as *marked* resolved and stays open for operators" is a problem.

**Solution.** Explain the approach and the decisions a reviewer could reasonably
question: why this approach, what alternatives were rejected and why, what is
deliberately out of scope, and any follow-up needed. Point at the one or two files
where the interesting logic lives. Finish with how to verify (test command, manual
steps, or screenshot). Do not list every changed file; the diff already does that.

Keep screenshots or images the user provided, placing them at the end of the
Solution section.

### 5. Create or update the PR

Write the body to a file in the scratchpad directory and pass it with `--body-file`;
inline `--body` mangles markdown and newlines.

```bash
gh pr view --json url,number 2>/dev/null   # does a PR already exist for this branch?
gh pr create --title "<title>" --body-file <path> [--draft]
gh pr edit <number> --title "<title>" --body-file <path>   # when one exists
```

Open as a draft only when the user says the work is not finished. Default base is
`main`.

### 6. Report

Show the user the PR URL, the title, and the full body you wrote, so they can correct
anything without opening the browser.

## Example body

```markdown
## The problem

Closes https://github.com/slovensko-digital/ops/issues/1237

When the author of an issue marks it as resolved, the issue is only flagged as
"marked as resolved" and stays in the operators' queue until someone confirms it.
For the author's own issues this confirmation step is pointless, so issues pile up
in the queue with nothing for operators to do.

## Solution

Treat a resolving update from the issue's author as a final resolution. In
`Issues::IssuesUpdatesController#create` the issue now moves to the `resolved` state
instead of `marked_as_resolved` when the update's author is the issue author. Updates
from other users are unchanged, so the confirmation flow for third-party resolutions
still applies. The existing triage sync job runs as before.

I considered adding a separate "resolve immediately" action, but that duplicates the
button for a single role; changing the target state in the existing branch keeps the
UI as it is.

Verify: run the issues controller tests, or open one of
your own issues, click *Resolve*, and check that it disappears from the operators' queue.
```
