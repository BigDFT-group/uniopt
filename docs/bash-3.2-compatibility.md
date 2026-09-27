# Bash 3.2 compatibility policy

UniOpt supports Bash 3.2 and later. Bash semantics remain part of the API; this
is not a POSIX `sh` library.

## Result API migration

The Bash 4.3 prototype assigned repeatable and remainder values to caller-named
arrays and implemented `uniopt_values ID OUTPUT_ARRAY` with `local -n`. Bash
3.2 has no namerefs and cannot safely initialize and populate an arbitrary
caller-named empty array without constructing shell code.

The portable API keeps multi-values in indexed records:

```bash
uniopt_parse "$@" || exit 2
uniopt_get_all compose.extra
extra_compose=("${UNIOPT_RESULT[@]}")

uniopt_get_unknown
compose_passthrough=("${UNIOPT_RESULT[@]}")
```

`UNIOPT_RESULT` is replaced by each multi-value getter. Values are copied
element by element internally, so spaces, empty strings, wildcard characters,
backslashes, Unicode, and newlines retain their argument boundaries.

Scalar `--dest` assignment remains supported. `uniopt_get` and
`uniopt_get_source` are the preferred scalar accessors; `uniopt_value` and
`uniopt_provenance` remain aliases. The second argument formerly accepted by
`uniopt_values` is rejected with an explicit diagnostic.

## Internal model

Semantic option IDs map to stable numeric indexes in parallel indexed arrays.
Separate indexed tables hold spellings, enum choices, alias assignments,
constraint members, and repeated result values. Lookups use explicit loops.
The core contains no associative arrays, namerefs, case-conversion expansion,
dynamic evaluation, generated parser scripts, or whitespace serialization of
argument arrays.

## Verification

CI has three independent jobs:

- Ubuntu with its current Bash;
- Ubuntu with GNU Bash 3.2 plus all 57 official patches, downloaded from GNU,
  checksum-verified, built locally, and asserted as version 3.2.57;
- macOS with `/bin/bash`, asserted to have major/minor version 3.2.

Every job syntax-checks the library, executable, examples, tests, and CI shell
scripts with its selected interpreter, runs the forbidden-feature audit, and
runs the complete behavior suite.

## Platform differences

GNU Bash 3.2.57 on Linux verifies the shell-language baseline. The macOS job
also covers Apple's system interpreter and standard command environment. It
does not exercise future WISE or ContainerXP Docker integration, filesystem
path normalization, case-insensitive filesystems, GUI launching, or other
application behavior because those projects are outside this compatibility
layer. Those are platform-integration concerns rather than shell-version
differences.
