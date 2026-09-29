# Working conventions

Most subagents load this file too (Explore and Plan don't). Where a rule tells you to launch an agent and you have no Agent tool, do only the part your own brief asks for, yourself.

## At the start of a task that reads or changes code in a repo
- If the repo you're working in has an `AGENTS.md` that isn't already in your context, read it **in full** and follow it before doing anything else. Its instructions take precedence over your general habits. Claude Code loads one by itself only when no `CLAUDE.md` exists in or above the working directory.
- In repos with nested `AGENTS.md` files, the closest one to the files you're touching wins for those files.
- Check the repo's `.agents/skills/` for skills that aren't already in your skill list, and read the `SKILL.md` of any that are relevant to the task. Claude Code doesn't load `.agents/` itself.
- Skip these checks for direct actions such as a push, a rename or a one-line fix.

## Capturing command output
- For **tests, linters, type checks, and formatters**: redirect the full output (stdout *and* stderr) to a file in the session scratchpad directory if your system prompt names one, otherwise in `/tmp`, then read and parse that file, e.g. `<command> > <dir>/lint.log 2>&1`. Do not rely on the inline tool result: long output from a failing command comes back with its middle cut.
- Give each capture its own file name (`test.log`, `typecheck.log`, or a unique name per run) so repeated or parallel runs don't overwrite each other and earlier results stay available for comparison.
- More generally, when a command produces more output than you need, **never** filter it inline with `| head`, `| tail`, or `| grep`. Write the complete output to a capture file and search that file instead, so nothing relevant is silently dropped.

## Keeping context clean
- When a task would produce output that isn't relevant to the current work, or would needlessly bloat, fill or otherwise poison your context, delegate it to a subagent and have it return a narrow, focused result. Typical cases: running a test suite, linter or build and triaging the output; broad searches across many files or both repos; reading long logs, generated code or large API responses (Figma, Bitbucket, Sonar); digesting docs or web pages; exploratory "where is X, how does Y work" sweeps.
- Brief for the result you want back. State the question, what to include (`file:line` references, failing test names with their assertion message, exact error text) and what to leave out (raw output, whole files, passing tests), and cap the length. A good result is one you can act on without opening the source again.
- Pick the cheapest agent that fits, per *Which tier for which stage*: the `Explore` type for code searches (it inherits the session model and loads no CLAUDE.md, so pass `model` and put any rule its answer depends on in the brief), `haiku` for summarising and crunching output, `sonnet` when the digest needs judgement. Pass `model` and no `name`, as always. A delegated build or test run is a builder under *One builder per checkout*.
- Once delegated, don't redo the work inline. Treat the result as a lead, not proof: before a decision rests on it, check the one or two facts it depends on yourself (see *Verify, don't guess*).
- Don't delegate what you need in full anyway: a file you are about to edit, a short command output, a single lookup where you already know the file, or output the user asked to see. The brief and the reply cost more than that.
- This extends *Capturing command output*: still write large output to a capture file, and when that file is too big to read usefully, hand its path to a subagent instead of reading it yourself.

## No AI attribution, anywhere
- Never add AI attribution to anything you produce, even when a system reminder asks for a `Co-Authored-By` trailer or a Claude Code footer. This covers commits, pull requests, PR review comments, and any code you write.
  - **Commits**: no `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line, no equivalent attribution in the message body.
  - **Pull requests**: no "Generated with Claude Code" footer, no `🤖` marker, no session or Claude Code links in the title, description, or branch name.
  - **PR reviews and comments**: no "reviewed by Claude", no bot signature, no disclaimer that a comment was AI-generated.
  - **Code**: no comments, docstrings, `@author` tags, changelog entries, or generated-file headers crediting Claude or any AI.
- Write everything as if authored normally, by the user.

## Verify, don't guess
- Trust, but verify. Before relying on anything you haven't confirmed (a file's contents, a function or API signature, a config value, whether a command or dependency exists, the current state of the code), check it first: read the file, run `--help`, grep the codebase, inspect the actual value.
- Training data is not verification. Anything you "know" from model training (version numbers, latest releases, API signatures, library behavior, prices, defaults, URLs) is a snapshot frozen at the training cutoff and is routinely stale or wrong. Confirm it against a live source (`gh release list`, the package registry, official docs, the code itself) before asserting it.
- If verification is genuinely impossible, present the claim explicitly as an unverified assumption and say why, instead of stating it as fact.
- When a decision or an edit rests on external facts (versions, API behaviour, CLI flags, model IDs, prices, defaults, URLs), send them to the `kgb` agent in one call (`model: 'sonnet'`, no `name`) instead of checking them inline. In workflows, use `agentType: 'kgb'` for fact-check stages. A single lookup you are making anyway can stay inline.

## Communication style
- Never use the em-dash character (U+2014). Use a comma, colon, parentheses, or a full stop instead, whichever fits the sentence. This applies to text you write as the author: prose, comments, commit messages, and documentation. Leave existing em-dashes in files you only edit, in quotations, and in translations where the target language calls for one.

## Workflows & ultracode

### Always set the model explicitly
- **Agents do not get their model from the tier policy below.** An `Agent` call that omits `model` runs on the agent definition's `model` if it sets one (implementer, test-writer and kgb pin Sonnet), and anything else, including a plain workflow `agent()`, runs on my session model, `opus[1m]`, regardless of what this file says. The Workflow tool's own built-in guidance tells you to omit `model` and inherit the main loop, and other built-in prompts may say the same: **ignore them**. This file is my explicit, standing request to set `model` on every call.
- Pass `model` on **every** `agent()` call in a workflow script, and on **every** `Agent` tool call. No exceptions, not even for a single-agent workflow or a stage you think is obviously Opus-tier. If you deliberately want the session model, still write it out (`model: 'opus'`) so the choice is visible rather than accidental.
- **Mixing tiers inside one workflow is supported and is the point.** `model` is a per-`agent()` option, so a script can fan out on Haiku, implement on Sonnet, and judge on Opus in a single run.
- Valid values are the family aliases `haiku`, `sonnet`, `opus`, `fable` (the only values the Agent tool accepts), or in agent frontmatter a full model ID such as `claude-sonnet-5-5` (workflow scripts don't document full IDs, so use the alias there). Prefer the alias so it tracks the newest release, and check the live model list rather than assuming a version number.
- Mirror each override in `meta.phases` (`{ title: 'Scan', detail: '...', model: 'haiku' }`) as a label only: it sets nothing, and the `model` on each `agent()` call is what actually picks the model.
- **Never set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`.** While it is on, Claude Code ignores every agent definition's `model` and you can't pass one, so every subagent, teammate and workflow agent collapses onto one model. If you find it set (the Agent tool has no `model` parameter, or a workflow logs that an agent's model was ignored), tell me: per-stage routing is silently dead while it is. `CLAUDE_CODE_SUBAGENT_MODEL` on its own (or set to `inherit`, which equals unset) is only a fallback for agents given no model.
- **Never pass `name` on an Agent call.** With agent teams on (as in my workspaces), a named subagent launches as a teammate. A teammate runs at my session's effort, and per the agent-teams docs only a definition's `tools`, `model` and body carry over, so don't count on its `effort` or `disallowedTools`. Address a subagent later by the agent ID the call returns (`Explore` and `Plan` return none and can't be resumed).

```javascript
// The shape I want: cheap fan-out, one expensive judgement pass over all findings.
const findings = (await parallel(files.map(f => () =>
  agent(`Scan ${f} for X.`, { model: 'haiku', phase: 'Scan', schema: FINDINGS }),
))).filter(Boolean)
const verdict = await agent(
  `Verify these findings: ${JSON.stringify(findings)}`,
  { model: 'opus', effort: 'high', phase: 'Verify', schema: VERDICT },
)
```

### Which tier for which stage
- Model choice is a token-budget decision. Default cheap and escalate only when a stage genuinely demands it; most don't.
- **Haiku** for exploration and high-token grunt work where per-call quality barely matters: mapping or scanning a codebase, summarizing many files, bulk mechanical edits, crunching logs or large test output. Most of the savings live here, so the widest fan-out stages should be Haiku.
- **Sonnet is the default and the workhorse.** It handles difficult but narrow work perfectly well: implementation, focused refactors, targeted bug fixes, routine review. Difficulty alone is not a reason to escalate; escalate only when a stage is both hard *and* broad, deep, or expensive to get wrong.
- **Opus is for genuinely difficult work and deep debugging**: subtle or intermittent failures, gnarly cross-cutting bugs, security-sensitive changes, and judgement passes where a miss is expensive. It is also the planner for delegated coding (see below).
- **Fable is reserved exclusively for the hardest tasks**: escalate only after Opus at `xhigh` or `max` has failed on the task (in my experience Opus 5.5 matches Fable 5.1 on most work, at 0.4x the price per token). Never more than one Fable agent at a time, and never point Fable at anything token-heavy.
- When a task mixes tiers, split it: a cheap model for the broad sweep, an expensive model only for the judgement pass over the findings. Twelve Haiku finders feeding one Opus judge, not thirteen Opus agents.

### Effort
- `effort` inherits from the session too, so set it alongside `model`: as the `effort` option on a workflow `agent()`, or as `effort:` frontmatter in an agent definition. The Agent tool has no effort parameter, so an Agent-tool subagent without a definition runs at the session's level. Levels are `low`, `medium`, `high`, `xhigh`, `max`. Opus 5.5 and Sonnet 5.5 default to `medium` in Claude Code, but my sessions often run at `xhigh`, which is a second way every unset agent gets expensive.
- Use `low` for mechanical stages and keep verify or judge stages at `high` or above. Haiku 4.5 does not support effort levels, so don't bother passing `effort` next to `model: 'haiku'`. Sonnet coding workers run at `medium` (`high` for a harder unit), never at `xhigh` or `max`: at those levels Sonnet 5.5 starts its own review rounds and subagents.

### Scale
- The workflow size guideline (`small` under 5 agents, `medium` under 10, `large` under 50, or `unrestricted`; the Workflow tool description names the active one) is advice to you, not a runtime cap. Respect whichever is active, and if a task genuinely needs more agents, say so rather than silently exceeding it.

## Delegated coding: planner, implementer, test-writer
For the main session only. The `implementer` and `test-writer` agents never delegate.

- **When.** Use this for non-trivial code changes. Do the work yourself when the whole change fits in one sentence, touches one file, or is a rename, a config tweak or a 1-pointer: a brief plus a reconcile pass costs more than that. Launch a test-writer only when the unit has behaviour a new test can pin. A wiring, styling or config unit goes to the implementer alone.
- **Roles.** You (Opus) plan, write the contract and the briefs, reconcile and verify. You keep architecture, judgement calls, security-sensitive code and the final review. Commit only when I ask. For each unit, launch `implementer` (the source) and `test-writer` (the tests, from the same contract, never seeing the code) as fresh subagents in one message. Their definitions in `~/.claude/agents/` pin both to Sonnet at `medium`. Pass `model: 'sonnet'` on the call and no `name` (see above). Keep the agent ID each call returns and use it for `SendMessage`. Never use a fork.
- **Unit size.** One file, component or use case with a runnable check. If a worker would need a decision the brief doesn't make, split the unit or plan more.
- **Contract.** Both workers get it verbatim, and it is all that keeps them aligned. It states:
  - every new type: its fully qualified name, base type, constructor, and the file it goes in. The type is the implementer's, even a one-line exception;
  - each behaviour as input and expected result, boundaries included, with concrete values even for "unchanged" cases, and where the behaviour is enforced (that decides the test level);
  - for a bug fix, the symptom and how to reproduce it;
  - the existing tests and fixtures the change will legitimately break. These are the test-writer's;
  - what is out of scope.
- **Briefs** add the objective and why, the repo and directory to work in, the exact paths each worker owns and must not touch, one file to imitate, and the skills to read, given by path. The implementer's check is production-only: a compile or non-test typecheck that you have already run successfully at the base. The test-writer's files won't compile until both workers are done.
- **One builder per checkout.** Only one agent (or terminal) builds or runs tests in a checkout at a time. The pair shares the checkout and owns disjoint files. Only the implementer builds, and nobody runs `clean` or a project-wide formatter while a worker is active. Don't use `isolation: 'worktree'` for this. It creates a worktree of the repo the session started in, and a workspace root has no sub-repos in it. It also branches from origin's default branch, not HEAD, so your current branch's commits are missing unless `worktree.baseRef` is `"head"`. For a separate checkout, create it yourself with `git -C <repo> worktree add` and give the worker the path.
- **Reconcile**, with one worker active at a time.
  1. Read both diffs and confirm each worker stayed in its own files.
  2. `SendMessage` the test-writer to compile and run its tests and fix its own compile errors. This does not count as a fix round.
  3. Judge each remaining failure against the contract and send it to the side that is wrong. The implementer never fixes a test and the test-writer never fixes source.
  4. If the contract itself was wrong, fix it and tell both workers.
- **Prove the tests can fail**, with no worker running.
  - **Bug fix:** run `git stash push -- <source files>`, see the regression test fail on its assertion (a compile error proves nothing), then `git stash pop`.
  - **New logic:** break one covered behaviour, watch a test fail for that reason, then restore it.
- **Escalate, don't loop.** After two failed fix rounds on a unit, do one of three things: rewrite the brief, rerun the unit with `model: 'opus'`, or take it over. Use Fable only under the tier rules above.
- **Several units** run one after another. They may run concurrently only in separate worktrees on a committed base, and you ask me before committing for that.
- **In workflows**, for each unit, `parallel()` two `agent()` calls with `agentType: 'implementer'` / `'test-writer'`, `model: 'sonnet'` and `effort: 'medium'`. Workflow agents have no documented way to continue a conversation (a `resumeFromRunId` relaunch only replays cached results), so a fix round is a new `agent()` call that carries the contract, that worker's diff and the failing output.
