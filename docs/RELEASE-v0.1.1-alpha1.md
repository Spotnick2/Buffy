# Buffy v0.1.1-alpha1 release checklist

This alpha contains Buffy issues #5-#11. The owner chose to release it after merge
without new in-game acceptance because the beta is closing. The new behavior is
unverified in game; [ACCEPTANCE.md](ACCEPTANCE.md) records the checks to run later.
The general procedure is `../References/Docs/RELEASING.md`.

## Before tagging

1. Done: [LibGroupBuffs #70](https://github.com/Spotnick2/LibGroupBuffs/pull/70) merged
   as `c7e2137` and [Buffy #12](https://github.com/Spotnick2/Buffy/pull/12) as `24dccd2`;
   Buffy's `main` package CI passed with 47 verified runtime files. Buffy keeps the
   immutable library commit pin `dcf34b7c7ae8228dbfb6d096e09d0465252f7397` (#70's head,
   reachable from LibGroupBuffs `main`) for this alpha; an `r33` tag waits for later
   in-game validation.
2. Check that `main` CI is green on the commit you are about to tag.
3. Tag that exact Buffy `main` commit `v0.1.1-alpha1` and push the tag.

## Publishing

Pushing the tag publishes in two places at once:

- **CurseForge:** the repository's tag webhook makes CurseForge build its own file
  from `.pkgmeta`. The `-alpha1` suffix makes it an **Alpha** file. This is the first
  Buffy build where CurseForge's packager fetches a `commit:` pin rather than a tag.
- **GitHub:** the tag's CI run checks its own ZIP and publishes it with `release.json`
  as a prerelease, using the matching CHANGELOG.md section as notes.

Then:

1. Watch the tag's run (`gh run list --event push --limit 5`, `gh run watch <id>`)
   and inspect the GitHub prerelease ZIP and `release.json` for the version, Forever
   interface, and dependency bytes.
2. Download CurseForge's ZIP from the project's Files tab and run
   `tests/check_package.py` on it. It must hold exactly the 47 runtime files with the
   LibGroupBuffs bytes at `dcf34b7`. Compare it with the GitHub ZIP before announcing.
   If CurseForge could not build from the commit pin, upload the checked GitHub ZIP
   manually as an Alpha for WoW: Forever 1.60.1 instead.
3. Keep issues #5-#11's in-game acceptance open. After game access returns, test the
   exact merged library revision and Buffy alpha against the checklist. Use those
   results to decide the stable release and LibGroupBuffs `r33` tag.
