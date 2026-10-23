# Maintaining the 5.3.0 skills

The public capability authority is the 5.3.0 manual. Code and features verify
restrictions; they cannot authorize undocumented capabilities. The supplied
5.3.2 server is accepted as compatible by the task owner. The skills work from
their own references and Python-standard-library helper after extraction.

Run maintenance commands from a repository checkout. The distribution bundles
this guide for reference; standalone skill usage needs only its bundled files.

## Offline gate

```sh
python3 scripts/check_all.py
```

This runs the original capability audit, unit/adversarial regressions, 37 NL
reference contracts, ZIP byte/link/layout validation and execution of each
standalone helper outside the checkout. No database or model key is needed.
GitHub Actions runs this on every PR and main push, including test-only changes.
The release job requires the successful validation job and publishes its exact
artifacts. PR jobs have no write permission.

## Model evaluation

```sh
python3 scripts/evaluate.py --export-prompts > prompts.json
python3 scripts/evaluate.py --outputs model-output.json --report dist/model-report.json
```

Give the model the exported prompts plus the chosen skill version, **not**
`evals/cases.json` (which holds reference GQL, assertions and result oracles).
Save `{producer: {kind: "model", model: "actual model id", skill_version: "sha"},
outputs: [{id, skill, query, explanation}]}`. `query` has no Markdown fences.
Omitted, duplicate or unknown IDs fail evaluation. `--ids` explicitly scopes a
partial run; never report it as whole-suite accuracy. References test the
harness, not the model. Trigger prompts are in `evals/triggers.json`; export
only id/prompt, hold expected_skill back from the model:

```sh
python3 scripts/evaluate.py --export-triggers > trigger-prompts.json
python3 scripts/evaluate.py --trigger-outputs route-output.json --report dist/routes.json
```

These are model route decisions, not measurements of an agent host auto-triggering.

Static checks cover documented names, common comma-style arities, known receiver
methods/scopes, targeted type errors, path/paging/procedure restrictions, repair
contracts and performance evidence claims. They are **not a complete GQL parser,
type checker or semantic proof**. Special signatures and unknown receiver types
are flagged for review. Live EXPLAIN and typed-result comparison provide stronger
evidence on the executable subset. Graph-schema-dependent contracts still need
review and a suitable fixture. Do not weaken cases merely to make model output
pass; correct ambiguous prompts and rerun both compared versions.

## Read-only database evaluation

Use an interpreter with `nebula5_python` 5.3.0 installed. Set `NEBULA_ADDRESS`,
`NEBULA_USER`, `NEBULA_PASSWORD` privately in the environment (never in a checked-in
command/configuration). Then:

```sh
python3 scripts/validate_database.py --report dist/database.json --performance
python3 scripts/validate_database.py --outputs model-output.json --report dist/model-database.json
```

Default execution is 12 constant/list fixtures, with three fixed original-error
reproductions followed by repair checks, server EXPLAIN and execution
and typed column/row comparisons. Duplicate multiplicity, NULL, ordering, large
integers and Decimal remain distinct. Only literal fixture results are compared;
reports omit query text, values and server exception payloads. The client uses a
10-second request timeout, a 100,000-row comparison budget (overflow fails
without truncation) and closes its own session. The guard rejects DDL/DML,
hints, procedure calls and graph access, even if they are valid generation tasks.
No upstream `.feature` file is executed: those files contain setup/writes.

Performance mode warms both candidates, alternates six paired executions,
checks full results on every iteration, and captures both PROFILE operator trees.
The included control changes pagination placement over four immutable scalar
rows. It proves the measurement mechanism and provides **no graph workload
speedup claim**. Six NL performance cases separately exercise supernodes, bounded
variable paths, intermediate multiplication, OPTIONAL, correlation and paging.
For representative graph performance, `evals/performance.json` supplies six
paired workload templates. Use a deliberately provisioned existing fixture,
record its snapshot/scale/indexes/settings, and apply the same equivalence-first
measurement contract. Run the opt-in suite with:

```sh
python3 scripts/validate_database.py --graph-performance evals/performance.json \
  --graph "$FIXTURE_GRAPH" --fixture-metadata fixture-metadata.local.json \
  --report dist/graph-performance.json
```

The metadata JSON requires `fixture`, `parameters`, `settings`, `scale`, `snapshot`.
These are operator-supplied descriptions, not measured statistics; describe index
and session configuration and capture the fixture snapshot independently. Observe
the per-case prerequisite in the suite, particularly bounded fanout for quadratic
output. The runner never provisions data or changes settings. It compares full
typed results before and during alternating timing, then checks PROFILE results.
Read-only failures/timeouts fail the run and prevent performance conclusions.
No representative graph run is implied by the scalar control; the six graph
workloads were not run here because no approved fixture schema/snapshot was given.

## Incremental refresh

```sh
python3 scripts/track_sources.py --docs-root "$DOCS_ROOT" --features-root "$FEATURES_ROOT" \
  --code-root "$CODE_ROOT" --code-ref v5.3.0 --report dist/source-impact.json
python3 scripts/refresh_documented_capabilities.py --docs-root "$DOCS_ROOT" --check
```

The versioned manifest stores hashes and relative source keys only. Source-change
check exits nonzero with affected cases; code/feature changes conservatively
select the entire suite. Documentation changes map by case documentation keys,
with full-suite fallback for unknown impact. This is an impact aid, not semantic
authorization. Review the diff against the pinned version; update curated
references and feature evidence selectively while retaining human edits.

Refresh without `--check` writes only the six **generated** catalogs (four function/syntax files and two reserved-keyword lists) whose
content changed. Other references, SKILL.md, cases and helper code remain intact. Reserved keywords govern identifier quoting only; they never authorize syntax capabilities.
Run the offline gate, relevant model/live cases and then explicitly accept the
new source snapshot using `track_sources.py ... --update`. A source-manifest
update alone does not certify coverage. Original local directories are optional
maintenance inputs and are never runtime dependencies of distributed skills.

The canonical helper is `scripts/skill_tools.py`; copy it into both skill script
directories after edits. A parity regression prevents drift between the copies.
Generated catalogs remain complete; bounded `lookup` retrieval reports its
continuation offset and never silently discards remaining evidence.
