# CLAUDE.md

This file provides guidance to AI assistants (Claude and others) working in this repository.

## Repository Status

This repository is newly initialized and currently empty. This CLAUDE.md serves as a
foundational reference that should be updated as the project grows.

---

## Repository Overview

- **Repository**: khuthy/fantastic-journey
- **Remote**: https://github.com/khuthy/fantastic-journey
- **Primary branch**: `main` (or `master` — update this once established)

When the project stack is chosen, update this section with:
- Language and runtime version
- Framework and key libraries
- Purpose / what the project does

---

## Development Branch

All AI-assisted changes should be developed on feature branches following this pattern:

```
claude/<short-description>-<random-suffix>
```

Example: `claude/add-claude-documentation-dWwAS`

**Never push directly to `main`/`master`** without an explicit instruction to do so.

---

## Git Workflow

### Branching

```bash
# Create and switch to a new feature branch
git checkout -b <branch-name>

# Push branch to remote and set upstream
git push -u origin <branch-name>
```

### Commits

Write clear, descriptive commit messages in the imperative mood:

```
Add user authentication module
Fix null pointer in order processing
Update README with setup instructions
```

- Keep the subject line under 72 characters
- Use the body to explain *why*, not *what*, when non-obvious
- Reference issue numbers where applicable: `Closes #42`

### Pull Requests

- Open a PR for every feature/fix before merging to the main branch
- Include a summary of changes and a test plan in the PR description
- Do not merge without at least one review (when team size allows)

---

## File & Directory Conventions

Update this section once the project structure is established. As a starting point:

```
fantastic-journey/
├── CLAUDE.md          # This file — AI assistant guidance
├── README.md          # Human-facing project documentation
├── .gitignore         # Files excluded from version control
└── src/               # Source code (update when added)
```

### General rules

- Keep files focused and single-purpose
- Prefer editing existing files over creating new ones
- Delete unused files rather than leaving them with comments like `// removed`
- Do not commit secrets, credentials, or `.env` files

---

## Coding Conventions

Update this section with language-specific conventions when the stack is chosen.
Until then, follow these universal principles:

- **Clarity over cleverness**: Write code that is easy to read and reason about
- **Minimal surface area**: Only add what is actually needed; avoid speculative abstractions
- **No dead code**: Remove unused variables, imports, and functions
- **Consistent naming**: Follow the conventions of the language/framework in use
- **Security first**: Never introduce command injection, XSS, SQL injection, or other OWASP Top 10 vulnerabilities

---

## Testing

Once a test framework is in place, document here:

- How to run the full test suite
- How to run a single test file
- Minimum coverage requirements (if any)
- Where test files live relative to source files

**Run tests before committing** any functional change.

---

## Linting & Formatting

Once linters/formatters are configured, document here:

- The tool(s) in use (e.g., ESLint, Prettier, Ruff, gofmt)
- How to run them: `npm run lint`, `make fmt`, etc.
- Whether formatting is enforced by a pre-commit hook or CI

**Do not disable linting rules** without a documented reason.

---

## Environment & Configuration

- Store secrets in environment variables, never in source code
- Provide a `.env.example` (committed) listing all required variables with placeholder values
- Never commit a `.env` file

---

## CI/CD

Document the CI pipeline here once configured:

- What CI system is used (GitHub Actions, CircleCI, etc.)
- When pipelines run (on push, on PR, nightly)
- What must pass before a PR can be merged

---

## AI Assistant Guidelines

When working as an AI assistant in this repository:

1. **Read before editing**: Always read a file before modifying it
2. **Minimal changes**: Only change what is necessary to complete the task; avoid refactoring unrelated code
3. **No speculative features**: Do not add functionality that was not requested
4. **Verify before pushing**: Confirm tests pass and linting is clean before pushing
5. **Ask when uncertain**: Use `AskUserQuestion` rather than guessing at ambiguous requirements
6. **Reversibility**: Prefer reversible actions; confirm before destructive operations
7. **Branch discipline**: Always develop on the designated feature branch, never on `main`
8. **Keep this file current**: Update CLAUDE.md whenever project conventions change

---

## Updating This File

This CLAUDE.md should be treated as living documentation. Update it when:

- The tech stack is chosen
- New tooling (linters, test frameworks, CI) is added
- Architectural decisions are made
- Team conventions are established

Keep it accurate and concise — prefer fewer, reliable rules over exhaustive ones.
