# Recorded model observations

Historical static-regression observations from the earlier audit. Current runtime quality evidence is in [quality/evidence/current](../quality/evidence/current/); do not treat these older static scores as current semantic acceptance.

These are actual saved model outputs from independent old/current skill agents,
not reference answers. Baseline is repository commit d414605. Each full run
processed 37 prompts in one agent batch; cases were instructed to be independent,
but shared-context/order effects remain. Single runs do not establish a general
accuracy estimate or variance. The tool did not supply exact model identifiers or
token telemetry, so `session-inherited` and unobserved tokens are explicit.

`current.json` is the final generation iteration, regraded against final checks.
The reserved-keyword checker was generalized after generation; scoring source
hashes are recorded separately and do not claim a frozen generation environment.
`iteration-1.json` preserves the prior improved run. `baseline.json` intentionally
contains errors and should not be used as reference GQL.

Routes are saved model choices, not measurements of a host's skill auto-triggering.
The final check pipeline validates the saved current outputs/routes as regression
artifacts; it does not invoke a model in CI. Export fresh prompts with evaluate.py
and regenerate outputs to measure a new skill/model change. Do not show these
files, evals/cases.json, or scoring assertions to the generator agent.
