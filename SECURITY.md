# Security policy

## Reporting a vulnerability

Do not open a public issue containing a credential, private token, source file, or reproduction that exposes sensitive data. Report only the affected component, provider, and non-sensitive reproduction steps through the repository owner's private security-reporting channel.

## Credential incident response

1. Revoke or rotate the affected credential at the provider.
2. Remove the value from the working tree, Git index, logs, build artifacts, and deployment configuration.
3. Replace hardcoded usage with an environment variable or managed secret reference.
4. Review provider audit logs and usage for unauthorized activity.
5. If the value entered Git history, treat it as compromised even after history is rewritten.

GaurdianAngel reports filenames and credential classes only. It must never print, store, or transmit matched values.
