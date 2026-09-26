# GaurdianAngel v1.2.0

GaurdianAngel is a repository-local pre-commit scanner that blocks supported hardcoded credentials before they enter Git history. It inspects the exact staged blobs and never sends source code or detected values over the network.

## Supported detections

| Provider or class | Recommended environment variable |
| --- | --- |
| OpenAI API keys, including project-prefixed keys | `OPENAI_API_KEY` |
| GitHub classic, OAuth, App, refresh, and fine-grained tokens | `GITHUB_TOKEN` |
| Slack bot, user, app, and related `xox*` tokens | `SLACK_TOKEN` |
| Google API keys | `GOOGLE_API_KEY` |
| Square legacy access and application credentials | `SQUARE_ACCESS_TOKEN` |
| Shopify shared secrets and access tokens | `SHOPIFY_ACCESS_TOKEN` |
| Quoted assignments using common credential variable names | Purpose-specific variable |

The provider list and common variable names incorporate the supplied `GitHub-Leaked-API-Keys-and-Secrets.md` reference. Patterns were updated for newer formats such as OpenAI project keys and GitHub fine-grained personal access tokens.

## Install

From the target repository root:

```bash
chmod +x /path/to/GaurdianAngel-v1.2.0/install.sh
/path/to/GaurdianAngel-v1.2.0/install.sh
```

The installer uses repository-local `core.hooksPath=.githooks`. It refuses to overwrite or bypass an existing pre-commit hook.

## Test

```bash
chmod +x tests/test.sh
./tests/test.sh
```

The tests use synthetic, inactive fixtures assembled only inside a disposable temporary repository.

## Continuous integration

The included GitHub Actions workflow runs the automated tests and scans every tracked file on pushes, pull requests, and manual dispatches. The workflow uses read-only repository permissions.

To perform the same full-repository scan locally:

```bash
GAURDIANANGEL_SCAN_ALL=1 .githooks/pre-commit
```

## Remediation workflow

If a commit is blocked:

1. Revoke or rotate the credential through its provider.
2. Remove the credential from the staged file and load its replacement from an environment variable or secret manager.
3. Add local environment files to `.gitignore`; commit only a value-free `.env.example`.
4. If the credential previously entered Git history, follow the provider's incident procedure and rewrite history when appropriate.

## Security characteristics

- Scans added, copied, modified, and renamed staged paths using NUL-delimited filenames.
- Reads stage-zero blobs directly from the Git index.
- Does not print matched values or matching source lines.
- Uses a private temporary directory and removes it on exit or interruption.
- Performs no outbound network requests.
- Includes a read-only GitHub Actions gate and monthly action-version updates.

Git hooks can be bypassed with `git commit --no-verify`, so enforce an independent secret scanner and push protection in CI or on the Git hosting platform as a second control.

## References

- [GitHub supported secret-scanning patterns](https://docs.github.com/en/code-security/reference/secret-security/supported-secret-scanning-patterns)
- [GitHub authentication token formats](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github)
- [OpenAI API-key safety](https://help.openai.com/en/articles/5008148-can-i-share-my-api-key-with-my-teammatecoworker)
- [Slack token types](https://api.slack.com/authentication/token-types)
- [Google Cloud API keys](https://docs.cloud.google.com/docs/authentication/api-keys)
- [Square access-token guidance](https://developer.squareup.com/docs/build-basics/access-tokens)

---
Engine Version: v1.0.0  
Core Architecture Engineered by: Fardeen Irani
