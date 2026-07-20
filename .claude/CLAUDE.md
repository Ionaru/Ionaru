# Working conventions

## At the start of every task
- If an `AGENTS.md` file exists, read it **in full** and follow it before doing anything else. Its instructions take precedence over your general habits.
- Check `.agents/skills/` for available skills and apply any that are relevant to the task.

## Capturing command output
- For **tests, linters, type checks, and formatters**: redirect the full output (stdout *and* stderr) to a file in `/tmp`, then read and parse that file, e.g. `<command> > /tmp/check.log 2>&1`. Do not rely on terminal scrollback.
- More generally, when a command produces more output than you need, **never** filter it inline with `| head`, `| tail`, or `| grep`. Write the complete output to `/tmp` and search the file instead, so nothing relevant is silently dropped.

## Git commits
- Never add AI attribution to commits. No `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line, no equivalent attribution in the commit message body. Write the commit message as if authored normally.

## Verify, don't guess
- Trust, but verify. When you're about to rely on something you haven't confirmed (a file's contents, a function or API signature, a config value, a version number or "latest" release, whether a command or dependency exists, the current state of the code), check it first rather than assuming. Read the file, run `--help`, grep the codebase, query the release list or registry, inspect the actual value. If verification isn't possible, say what you're assuming and why, instead of presenting a guess as fact.
- Training data is not verification. Anything you "know" from model training (version numbers, latest releases, API signatures, library behavior, prices, defaults, URLs) is a snapshot frozen at the training cutoff and is routinely stale or wrong. Recalling it confidently is not the same as it being correct. Never state such a fact from memory: confirm it against a live source (`gh release list`, `--help`, the package registry, official docs, the code itself) before asserting it. If you genuinely cannot look it up, label it explicitly as an unverified recollection rather than stating it as fact.

## Communication style
- Never use the em-dash character (`—`). Use a comma, colon, parentheses, or a full stop instead, whichever fits the sentence. This applies to all prose, comments, commit messages, and documentation.
