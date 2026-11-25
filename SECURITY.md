# Security policy

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Report them privately through GitHub's
[private vulnerability reporting](https://github.com/shravanbotuku/jenkins-on-ecs-fargate/security/advisories/new)
(Security tab → "Report a vulnerability").

Please include:

- what you found and where (file and line, or resource name)
- how to reproduce it
- the impact you expect

You can expect an acknowledgement within 5 working days.

## Scope

This repository is a reference implementation. It holds no real credentials,
account IDs or environment values; `*.tfvars` and backend configs are kept out
of Git. If you find anything that looks like a real secret, please report it as above.

## Controls in this repository

- Secret scanning with push protection, plus a gitleaks scan in CI
- Dependabot alerts and security updates
- Signed commits required on `main`; changes reach `main` only through pull requests
- GitHub Actions restricted to an allow-list, pinned to full commit SHAs, with a read-only default token
