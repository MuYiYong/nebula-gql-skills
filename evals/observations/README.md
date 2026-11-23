# Recorded model observations

`current.json` holds the 37 answers generated against the skill snapshot recorded in its producer metadata and in [scoring-sources.json](scoring-sources.json). A separate blind run supplied the 16 decisions in `current-routes.json`. The route score measures saved decisions. The static contract score measures query shape and explanation requirements. For executed results, see the [graph-free model checks](../reports/database-current.json) and [scoped semantic suite](../quality/evidence/current/model-run.json).

## Identifier-quoting refresh

The pre-refresh batch scored 5/37 under the new checks. The first fresh batch scored 27/37. A second fresh context received the same 37 public prompts plus an explicit client contract. Nonempty queries must be executable, essential missing Schema or side effects require clarification, ordinary label matches and exact-type requests use their respective syntax, and unmeasured performance must be identified. It scored 37/37. Both runs shared context across questions within their batch. Neither generator had access to previous responses, the grading criteria, or the reference queries. These results describe this regression suite and prompting setup. [First fresh batch](history/2026-11-23-first-batch.json) · [Earlier observations](history/pre-all-identifiers/current.json)

## Reproducing the evaluation

Export public tasks with `python3 scripts/evaluate.py --export-prompts` and route requests with `--export-triggers`. Give the generator the exported prompts and the matching skills. Check the skill directory actually resolved by the model when multiple versions are installed. Keep `evals/cases.json`, historical outputs and grading code out of its context. CI scores saved responses offline.

The earlier baseline uses repository commit `d414605`. `iteration-1.json` preserves an earlier generation iteration. The archived scoring manifest records the scoring sources for the pre-refresh batch. [Historical scoring sources](history/pre-all-identifiers/scoring-sources.json)
