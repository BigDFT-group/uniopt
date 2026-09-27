# WISE and ContainerXP integration preview audit

The integration examples were compared on 2026-09-27 with these local source
trees:

- WISE `/workspace/Sync/gitprojects/WISE`, HEAD
  `4a1d5996b4ce1acbab083ac3b650c7b4637b2ef1`, including current uncommitted and
  untracked command scripts;
- ContainerXP `/workspace/Sync/gitprojects/ContainerXP`, HEAD
  `8935821fe8b9b68e5439a0243c66880830baf771`, including current uncommitted and
  untracked command scripts.

The snapshot hashes identify the repository bases, but several inspected
scripts are outside those commits. The examples are therefore migration
prototypes, not a claim that upstream interfaces can never change.

## Modeled interfaces

| Source command | UniOpt preview | Behaviors exercised |
|---|---|---|
| `wise-env` | `bin/wise-env` | session selectors, enums, repeatable publish, tri-state host integration, store-constant alias |
| `wise-up` | `bin/wise-up` | shared selectors, repeatable Compose files, negative actions, passthrough arguments |
| `wise-down` | `bin/wise-down` | compound prune alias and internal target |
| `wise-shell` | `bin/wise-shell` | exact remainder argv after `--` |
| `wise-host-open` | `bin/wise-host-open` | mutually exclusive action modes |
| `dockerfile-to-wise-sdk` | matching preview | required path option and required positional input |
| `bigdftmk` | matching preview | shared ContainerXP flags, environment-derived defaults, short/long values, passthrough |
| `laramk` | matching preview | several source paths, image, credentials path, port |
| `latexmk` | matching preview | source/output paths and legacy shared flags |

The previews stop after parsing. Path resolution, Docker argument assembly,
subnet validation, URL/file security checks, environment-file mutation, and
all other domain transformations remain in the calling application, as
required by UniOpt's design.

## Known differences and migration decisions

1. ContainerXP's predecessor generates and sources `uniopt_tmpfile.sh`, uses
   `eval` for declarations, and flattens positional arguments into strings.
   The previews intentionally use indexed arrays and preserve argv elements.
2. `laramk` declares `--sources` for both `SOURCEDIR` and `LARASOURCE`. The
   generated shell `case` makes the second long spelling unreachable. The
   preview preserves working `-l` and introduces `--lara-sources` as the clear
   migration spelling. This needs an explicit compatibility note in an actual
   ContainerXP change.
3. `latexmk` declares `-x` for both shared `--extra-cmd` and `--extradir`; the
   first generated branch wins. The preview keeps working `-x` for
   `--extra-cmd` and exposes `--extradir` only by its usable long spelling.
4. The WISE `wise-shell` example guarantees exact command arguments after
   `--`. WISE currently also accepts some command tokens without the separator.
   Requiring `--` for option-looking command arguments is the unambiguous
   portable contract.
5. WISE conditional rules such as “publish requires sidecar bridge mode” depend
   on option values. UniOpt's current relationship constraints operate on
   explicit occurrence, so those value-dependent checks remain domain
   validators in WISE.
6. ContainerXP boolean declarations toggle an `ASSUME_YES` or `ASSUME_NO`
   default. The modeled commands use their actual `ASSUME_NO` flags. A general
   compatibility adapter must also preserve the inverse case.

## Estimated integration work

The schemas show that parser replacement is small compared with application
separation. WISE already stores argv in arrays and has structured help, so its
work is mainly extracting side-effect-free schema functions, replacing each
manual parsing loop, and installing generated completion. ContainerXP needs a
larger change: application code currently constructs Docker command strings,
relies on generated parser files, and stores positional arguments as a flattened
string. Its adapter should first translate old declarations, then callers must
move command construction to arrays before execution can be considered safe.

Neither source repository is modified by this preview.
