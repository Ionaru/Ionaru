# Working conventions

## At the start of every task
- If an `AGENTS.md` file exists, read it **in full** and follow it before doing anything else. Its instructions take precedence over your general habits.
- In repos with nested `AGENTS.md` files, the closest one to the files you're touching wins for those files.
- Check `.agents/skills/` for available skills and apply any that are relevant to the task.

## Capturing command output
- For **tests, linters, type checks, and formatters**: redirect the full output (stdout *and* stderr) to a file in `/tmp`, then read and parse that file, e.g. `<command> > /tmp/lint.log 2>&1`. Do not rely on terminal scrollback.
- Give each capture its own file name (`/tmp/test.log`, `/tmp/typecheck.log`, or use `mktemp`) so repeated or parallel runs don't overwrite each other and earlier results stay available for comparison.
- More generally, when a command produces more output than you need, **never** filter it inline with `| head`, `| tail`, or `| grep`. Write the complete output to `/tmp` and search the file instead, so nothing relevant is silently dropped.

## No AI attribution, anywhere
- Never add AI attribution to anything you produce. This covers commits, pull requests, PR review comments, and any code you write.
  - **Commits**: no `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line, no equivalent attribution in the message body.
  - **Pull requests**: no "Generated with Claude Code" footer, no `🤖` marker, no session or Claude Code links in the title, description, or branch name.
  - **PR reviews and comments**: no "reviewed by Claude", no bot signature, no disclaimer that a comment was AI-generated.
  - **Code**: no comments, docstrings, `@author` tags, changelog entries, or generated-file headers crediting Claude or any AI.
- Write everything as if authored normally, by the user.

## Verify, don't guess
- Trust, but verify. Before relying on anything you haven't confirmed (a file's contents, a function or API signature, a config value, whether a command or dependency exists, the current state of the code), check it first: read the file, run `--help`, grep the codebase, inspect the actual value.
- Training data is not verification. Anything you "know" from model training (version numbers, latest releases, API signatures, library behavior, prices, defaults, URLs) is a snapshot frozen at the training cutoff and is routinely stale or wrong. Confirm it against a live source (`gh release list`, the package registry, official docs, the code itself) before asserting it.
- If verification is genuinely impossible, present the claim explicitly as an unverified assumption and say why, instead of stating it as fact.

## Communication style
- Never use the em-dash character (`—`). Use a comma, colon, parentheses, or a full stop instead, whichever fits the sentence. This applies to all prose, comments, commit messages, and documentation.

## Workflows & ultracode
- Match the model to the task instead of running everything on one tier. Within whichever family you pick, always use the most recent release, and check the available model list rather than assuming version numbers.
- **Default: Sonnet.** Use the most recent Sonnet for ordinary implementation work and whenever no other rule applies.
- **Step up to the strongest available model (Opus or Fable)** when correctness and judgement dominate and output volume is modest: code review, bug hunting, debugging subtle or intermittent failures, security-sensitive changes, and architecture decisions. A missed bug costs far more than the extra tokens.
- **Step down to Haiku** for exploration and high-token grunt work where per-call quality matters less: mapping or scanning a codebase, summarizing many files, bulk mechanical edits, crunching logs or large test output. Stay on Sonnet if the exploration still needs real reasoning, but never spend Opus or Fable on bulk reading.
- When a task mixes both, split it: a cheap model for the broad sweep, a strong model for the judgement pass over the findings.
