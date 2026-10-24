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

## Outcome (2026-10-24)

v0.1.1 went out as its third alpha. alpha1 and alpha2 publish nowhere else and can be deleted.

| Tag | Library pin | GitHub | Wago | CurseForge |
|---|---|---|---|---|
| v0.1.1-alpha1 (annotated) | `commit: dcf34b7` | prerelease | - (no job yet) | no file |
| v0.1.1-alpha2 (lightweight) | `commit: dcf34b7` | prerelease | alpha | no file |
| v0.1.1-alpha3 (lightweight) | `tag: r33` (= dcf34b7) | prerelease | alpha | Alpha, approved |

- **CurseForge builds nothing from a `commit:` pin.** Its webhook answered `{"success":true}`
  to both commit-pinned tags and to a redelivery of alpha1, and no file ever appeared, with no
  error. Ruled out before alpha3: the tag type (alpha2), the alpha file type (Priestly's alpha
  built), the token (valid), CurseForge being down (AltStable built meanwhile). LibGroupBuffs
  tagged `r33` on the same commit, and alpha3 built within minutes. Recorded in
  `../References/Docs/EMBEDDED-LIBRARIES.md` §3 and `RELEASING.md`.
- **CurseForge's alpha3 ZIP** (`Buffy-v0.1.1-alpha3.zip`, file 9305968) passes
  `tests/check_package.py`: 47 runtime files, LibGroupBuffs bytes at r33, LibGlass at r11.
- **Wago** (project QNl4o8Ne) first published through CI with alpha2 (#26).
- In-game acceptance of issues #5-#11 is still open ([ACCEPTANCE.md](ACCEPTANCE.md)); the
  stable v0.1.1 waits for it.
