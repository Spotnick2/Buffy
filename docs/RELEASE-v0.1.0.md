# Buffy v0.1.0 release checklist

This branch prepares GitHub release packaging and player-facing v0.1.0 notes. The
existing `.work/release-candidate/v0.1.0-alpha1/` ZIP is an unpublished preview
with a development library pin; it is not the final v0.1.0 archive.

## Companion work

1. [LibGroupBuffs #69](https://github.com/Spotnick2/LibGroupBuffs/pull/69)
   merged as `b51d77573924b802b28561b028c4dc125fcdadbe`. Its CI passed,
   the merge tree matches the reviewed head, and the owner confirmed the
   merged library works in game. The published `r32` tag points to that merge.
2. The owner reviews and merges [GlassUI #160](https://github.com/Spotnick2/GlassUI/pull/160).
   Its CI passed and it is mergeable. Buffy works without it, but following
   GlassUI from the hub needs that roster entry.
3. Buffy's `.pkgmeta` now pins LibGroupBuffs with `tag: r32`. The Buffy,
   LibGroupBuffs, and Priestly suites passed against the `r32` checkout and
   LibGlass `r11`; the local staged package passed the 47-file byte check.
   Confirm the PR package check also passes with this pin.

## GitHub and CurseForge

1. Merge this release-preparation PR after its CI passes and the library pin
   has been updated. Check `main` CI before creating a tag.
2. Tag that exact Buffy `main` commit `v0.1.0` and push the tag. The tag run
   checks the ZIP and publishes it with `release.json` and the v0.1.0 changelog
   section as a GitHub Release. Confirm both assets and the ZIP's version.
3. Buffy is currently a private GitHub repository. CurseForge project 1760483
   can receive a manual upload of the checked GitHub ZIP, with release type
   **Release** and WoW: Forever 1.60.1 selected. Paste the locally maintained
   `README.curseforge.md` into the project description if it needs updating.
   If automatic tag packaging is desired instead, the owner must first configure
   a working CurseForge repository webhook and verify access to the source.
4. Download CurseForge's accepted ZIP and run `tests/check_package.py` on it.
   It should contain only the 47 declared runtime files and the intended
   dependency revisions. Compare it with the GitHub ZIP before announcing the
   release.

Owner acceptance so far covers general Priest and Mage use and Mark of the Wild
on Druid. Detailed combat, persistence, and other class scenarios remain in
[ACCEPTANCE.md](ACCEPTANCE.md).
