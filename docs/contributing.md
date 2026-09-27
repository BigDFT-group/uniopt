# Contributing

The repository contribution instructions are maintained in
[`CONTRIBUTING.md`](https://github.com/bigdft-group/uniopt/blob/main/CONTRIBUTING.md).

Run the complete suite before submitting a change:

```bash
./tests/all.sh
```

When declarations or public documentation change, regenerate and verify all
derived files:

```bash
./scripts/generate-docs
./scripts/generate-integration-docs
./scripts/generate-llms
./scripts/check-docs
```
