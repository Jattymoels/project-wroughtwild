# Game Project Placeholder

The engine project will live here after ADR-0001 is accepted.

Do not initialize multiple engines in parallel. When an engine is selected:

1. record the exact version in `docs/decisions/ADR-0001-engine-selection.md`;
2. add the official engine-specific `.gitignore` rules;
3. commit the smallest launching project;
4. document clean-checkout launch steps in the root `README.md`;
5. keep generated imports, caches, builds and local editor state out of Git.

The engine layer should keep gameplay rules separable from scenes, presentation and input where practical.
