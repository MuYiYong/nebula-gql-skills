# Security and privacy

This repository distributes documentation-driven skills and their test fixtures. It must not contain production credentials or private user data.

Do not commit or paste any of the following into source files, examples, tests, issues, or pull requests:

- API keys, access tokens, passwords, private keys, or credential-bearing URLs.
- Exported provider or application configuration.
- Session transcripts, local logs, customer data, or other personal data.
- Machine-local paths that identify a private workstation or workspace.

If sensitive information is found in a commit, do not open a public issue with the value. Remove or rotate the credential first, then contact the repository owner privately and include only the commit, path, and remediation details needed to investigate. Public repository history may require a separate history-cleanup operation after a credential is rotated.

The values used in the vendored feature tests are test fixtures or environment-variable placeholders. They must never be replaced with credentials from a real NebulaGraph, S3, MinIO, or other service.
