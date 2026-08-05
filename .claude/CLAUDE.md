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

### Always set the model explicitly
- **Agents do not inherit the tier policy below, they inherit the session model.** My session model is set to `opus[1m]`, so every `agent()` call that omits `model` runs on Opus regardless of what this file says. The Workflow tool's own built-in guidance tells you to omit `model` and inherit the main loop: **ignore it**. These instructions override it.
- Pass `model` on **every** `agent()` call in a workflow script, and on **every** `Agent` tool call. No exceptions, not even for a single-agent workflow or a stage you think is obviously Opus-tier. If you deliberately want the session model, still write it out (`model: 'opus'`) so the choice is visible rather than accidental.
- **Mixing tiers inside one workflow is supported and is the point.** `model` is a per-`agent()` option, so a script can fan out on Haiku, implement on Sonnet, and judge on Opus in a single run.
- Valid values are the family aliases `haiku`, `sonnet`, `opus`, `fable`, or a full model ID such as `claude-sonnet-5`. Prefer the alias so it tracks the newest release, and check the live model list rather than assuming a version number.
- Mirror each override in `meta.phases` (`{ title: 'Scan', detail: '...', model: 'haiku' }`) so the progress view shows what a phase actually costs.
- **Never set `CLAUDE_CODE_SUBAGENT_MODEL`.** It overrides both the per-agent `model` option and the script's routing, collapsing every tier back onto one model. If you find it already set in the environment, tell me: per-stage routing is silently dead while it is. `inherit` is equivalent to unset.

```javascript
// The shape I want: cheap fan-out, expensive judgement pass.
const findings = await pipeline(
  files,
  f => agent(`Scan ${f} for X.`, { model: 'haiku', effort: 'low', phase: 'Scan', schema: FINDINGS }),
  r => agent(`Verify these findings.`, { model: 'opus', phase: 'Verify', schema: VERDICT }),
)
```

### Which tier for which stage
- Model choice is a token-budget decision. Default cheap and escalate only when a stage genuinely demands it; most don't.
- **Haiku** for exploration and high-token grunt work where per-call quality barely matters: mapping or scanning a codebase, summarizing many files, bulk mechanical edits, crunching logs or large test output. Most of the savings live here, so the widest fan-out stages should be Haiku.
- **Sonnet is the default and the workhorse.** It handles difficult but narrow work perfectly well: implementation, focused refactors, targeted bug fixes, routine review. Difficulty alone is not a reason to escalate; escalate only when a stage is both hard *and* broad, deep, or expensive to get wrong.
- **Opus is for genuinely difficult work and deep debugging**: subtle or intermittent failures, gnarly cross-cutting bugs, security-sensitive changes, and judgement passes where a miss is expensive.
- **Fable is reserved exclusively for the hardest tasks**, the ones where Opus has failed or clearly won't cut it. Never more than one Fable agent at a time, and never point Fable at anything token-heavy.
- When a task mixes tiers, split it: a cheap model for the broad sweep, an expensive model only for the judgement pass over the findings. Twelve Haiku finders feeding one Opus judge, not thirteen Opus agents.

### Effort
- `effort` is a separate per-agent option and it inherits from the session too, so set it alongside `model`. Levels are `low`, `medium`, `high`, `xhigh`, `max`; `high` is the model default and ultracode pins the session to `xhigh`, which is a second way every unset agent gets expensive.
- Use `low` for mechanical stages and keep verify or judge stages at `high` or above. Haiku 4.5 does not support effort levels, so don't bother passing `effort` next to `model: 'haiku'`.

### Scale
- The workflow size guideline (`small` under 5 agents, `medium` under 15, `large` under 50, or `unrestricted`) is advice to you, not a runtime cap. Respect whichever is active, and if a task genuinely needs more agents, say so rather than silently exceeding it.
