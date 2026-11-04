# Buffy

A group buff manager for **World of Warcraft: Forever**, automatically choosing Priest,
Druid, or Mage behavior. Buffy combines Priestly, Wildly, and Magely through their shared
LibGroupBuffs engine and LibGlass window.

![Buffy in action with Lord Kazzak in the background](https://raw.githubusercontent.com/Spotnick2/Buffy/main/docs/screenshots/buffy-kazzak-gameplay-v1.gif)

| Class | Buffs |
| --- | --- |
| Priest | Fortitude, Spirit, Shadow Protection; instance and aura detection modes |
| Druid | Mark/Gift of the Wild; Thorns on tanks, yourself, everyone, automatically, or disabled |
| Mage | Intellect/Brilliance; independent Amplify and Dampen modes and instance selections |

Left-click a row to cast a group buff when learned, or a single buff otherwise. Right-click
casts a single buff on the first eligible member missing it. Hover for individual member
buttons. Reagent counters appear for the spells you know. Secure window changes wait until
combat ends. Unsupported classes create no buff window.

![Buffy tracking Arcane Intellect across two groups and pets, with individual member buff status](https://raw.githubusercontent.com/Spotnick2/Buffy/main/docs/screenshots/buffy-mage-raid.png)

## Commands and settings

`/buffy` toggles the window. Available commands: `show`, `hide`, `config`, `reset`, `pos`,
`test`, `help`, and `toggle`. Help includes localized spell names and dependency diagnostics.

`/buffy test 5` or `/buffy test 8` previews the window with five or eight full groups, so you
can place and size it before a raid. Clicks never cast in the preview. `/buffy test off`, or any
other `/buffy` command, returns to your live group. The preview starts only out of combat, and
if you turn it off in combat the live group returns when combat ends.

In `/buffy config`:

- **Window growth:** down keeps the header in place as rows appear, up keeps the footer in place.
- **Show reagent footer:** hide the reagent counters at the bottom of the window.
- **Priest:** *Always show Shadow Protection in battlegrounds*, whichever mode Shadow
  Protection otherwise uses.
- **Vendor restocking** (off by default): the reagents for the group buffs you know and track.
  Priests buy Holy or Sacred Candles for their Prayer ranks, Druids the Gift of the Wild reagent
  for their rank, and Mages Arcane Powder once they know Arcane Brilliance. When you open a
  merchant who sells them for gold, Buffy buys up to the target you set, within your money and
  bag space, and says what it bought.

Settings are shared by characters of the same class. Position and visibility are per character.
Buffy starts with fresh settings and does not import settings from the original addons.
Disable the matching original addon when using Buffy to avoid duplicate buff windows.

## Good to know

- The features added in 1.0 (battleground Shadow Protection, window growth, the preview, the
  footer option and vendor restocking) have passed offline tests but are still being checked on
  the live client. Please report anything that misbehaves.
- A `?` on a member means Buffy can't read that aura right now or the member is out of range.

## GlassUI

GlassUI is optional and not released yet; until it is, Buffy uses its Clean look. Once a
GlassUI version with the Buffy roster entry is available, Buffy appears in its hub while
loaded and follows its material, body tint/backing, and accent. Change its follow
switch or appearance in GlassUI, then `/reload`. Local opacity is disabled while following;
its saved value returns when following is off. Without a compatible suite, Buffy uses Clean.
Class/spec icons and buff-status colors retain their meaning.

## Development

This checkout needs the companion LibGroupBuffs implementation; see
[implementation status](https://github.com/Spotnick2/Buffy/blob/main/docs/IMPLEMENTATION.md). A source archive without embedded libraries
is not a game installation. Build a staged package using:

```powershell
pwsh tests/run.ps1 -Library .work/LibGroupBuffs -LibGlass .work/LibGlass-r11
pwsh Tools/package.ps1 -Library .work/LibGroupBuffs -LibGlass .work/LibGlass-r11
$env:LIBGROUPBUFFS = "$PWD/.work/LibGroupBuffs"
$env:LIBGLASS = "$PWD/.work/LibGlass-r11"
python tests/check_package.py .work/package
```

The package script requires a fresh destination. Pass `-Destination` for another staging
directory. `Tools/deploy.ps1` is a separate, explicit development deployment tool.

Offline validation does not establish in-game acceptance. Use the checklist in
[docs/ACCEPTANCE.md](https://github.com/Spotnick2/Buffy/blob/main/docs/ACCEPTANCE.md), including a full restart to verify persistence.

CurseForge project: **1760483**. Interface: **16001**. Author: **Spotnick**.
