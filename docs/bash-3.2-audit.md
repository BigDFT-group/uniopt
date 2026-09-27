# Bash 3.2 compatibility audit

This audit records the state of UniOpt before the Bash 3.2 refactor.

## Incompatible constructs found

| Location | Construct | Effect on Bash 3.2 | Replacement |
|---|---|---|---|
| `lib/uniopt.sh` startup | Explicit Bash 4.3 version guard | Refuses to load | Require Bash 3.2 |
| `uniopt_reset` | `declare -gA` | `-A` and `-g` are unavailable | Parallel indexed arrays keyed by stable numeric item indexes |
| Registry access throughout the library | Associative subscripts keyed by semantic IDs and spellings | Associative arrays are unavailable | Linear ID/spelling lookup returning numeric indexes |
| Result assignment and copying | `local -n` namerefs | Namerefs are unavailable | Internal indexed result records and getter functions; validated scalar assignment remains via `printf -v` |
| Help rendering | `${id^^}` | Case conversion expansion is unavailable | Metavars or the unchanged semantic ID as fallback |
| `tests/run.sh` | `local -n` in `assert_array` | Test suite does not parse | Compare the fixed `UNIOPT_RESULT` array element by element |

## Requested constructs not found

The pre-refactor tree did not use `mapfile`, `readarray`, `${value,,}`, `[[ -v
... ]]`, `&>>`, `|&`, `coproc`, or negative array indexes. It did not generate
or source parser scripts. The only occurrences of `eval` were documentation and
a literal injection-test payload; no parser path called it.

## Public API impact

Scalar destinations remain supported because `printf -v` is present in Bash
3.2 and destination identifiers are validated before use. Dynamic defaults
also retain their output-variable callback contract.

The old `uniopt_values ID OUTPUT_ARRAY` implementation depended on a nameref.
The portable API is `uniopt_get_all ID`, which copies exact elements into the
fixed indexed array `UNIOPT_RESULT`. `uniopt_values` remains as a compatibility
alias but now has the same one-argument/result-array contract. Repeatable,
remainder, and unknown values are held internally rather than assigned through
dynamic array names. This avoids `eval`, unsafe array-subscript construction,
and the inability to initialize an empty caller-named array safely in Bash 3.2.

The scalar names `uniopt_value` and `uniopt_provenance` remain as aliases for
the clearer `uniopt_get` and `uniopt_get_source` names.

## CI state before refactoring

No CI configuration existed. The project ran one test script using whichever
`bash` appeared in the environment. The refactor adds current-Bash, pinned GNU
Bash 3.2.57, and macOS `/bin/bash` jobs plus syntax and forbidden-feature
checks.
