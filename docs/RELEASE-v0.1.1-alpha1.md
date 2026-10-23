# Buffy v0.1.1-alpha1 release checklist

This alpha contains Buffy issues #5-#11. The owner chose to release it after merge
without new in-game acceptance because the beta is closing. The new behavior is
unverified in game; [ACCEPTANCE.md](ACCEPTANCE.md) records the checks to run later.

## Before tagging

1. Merge [LibGroupBuffs #70](https://github.com/Spotnick2/LibGroupBuffs/pull/70), then
   [Buffy #12](https://github.com/Spotnick2/Buffy/pull/12), after their required CI checks
   pass. Buffy keeps the published immutable library commit pin
   `dcf34b7c7ae8228dbfb6d096e09d0465252f7397` for this alpha; an `r33` tag waits
   for later in-game validation.
2. Check Buffy's `main` package CI and its exact ZIP manifest. Confirm that the 47
   runtime files include the pinned LibGroupBuffs and LibGlass sources and licenses.
3. Tag that exact Buffy `main` commit `v0.1.1-alpha1`. The tag workflow marks alpha
   tags as GitHub prereleases and uses the matching CHANGELOG.md section as notes.

## Publishing

1. Inspect the GitHub prerelease ZIP and `release.json` for the version, Forever
   interface, and dependency bytes.
2. If uploading the checked ZIP manually to CurseForge project 1760483, choose
   release type **Alpha** and WoW: Forever 1.60.1. Download the accepted ZIP and
   run `tests/check_package.py` on it before announcing the release.
3. Keep issues #5-#11's in-game acceptance open. After game access returns, test the
   exact merged library revision and Buffy alpha against the checklist. Use those
   results to decide the stable release and LibGroupBuffs `r33` tag.
