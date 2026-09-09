# ART-07 — serial publication and dispatch coordination

Copy the complete prompt below into the coordinating session. Run one publisher
at a time after workers have delivered checked branch commits and receipts.

```text
Coordinate publication of completed ART-07 slices only.
Repository: C:/Users/Matty/Dev/project-wroughtwild

Read AGENTS.md and follow its required reading order. Inspect the actual main
checkout, origin URL, dirty work and recent local/remote history before edits.
Read docs/prototype/art07-production/README.md, COMMON.md, PROCESS.md and plan.json.
Origin is the owner-approved https://github.com/Jattymoels/project-wroughtwild.git.

Find completed worker receipts and exact branch commit(s) for codex/art07-<id>.
Use the worker's final report and inspected Git history to resolve a receipt's
commit; a commit cannot embed its own hash. Do not guess completion from a branch
name or a planned queue row. No task is complete merely because a GLB exists.

For ONE ready checked slice at a time:
1. Verify dependency receipts, actual input hashes and local package paths.
2. Inspect the whole diff and ensure it contains only that slice's authorized
   paths. Review actual model evidence against the selected concept and note
   any outstanding human visual acceptance separately from technical clearance.
3. Run that slice's meaningful verifier and fresh-package check. Do not rerun
   expensive generation just to publish, and serialize any necessary GPU work.
4. Integrate the exact checked worker commit(s) onto main without rewriting
   history, using fast-forward or cherry-pick as appropriate to actual ancestry.
   Preserve unrelated captures, saves and working changes. Do not reset, clean,
   force-push or stash someone else's work. If files genuinely conflict, inspect
   and resolve within this slice; do not silently choose an entire branch.
5. Update only this slice's receipt and shared ART-07 work item/queue/roadmap
   status. Record worker source SHA(s), test evidence, local bundle identity,
   limitations and which dependencies are now ready. Do not mark future rows
   implemented or infer owner visual approval from a technical pass.
6. Check the resulting diff, relevant documentation/catalogue validators and
   scope. Commit necessary publication notes, then make an ordinary non-force
   push to origin/main under the owner's standing permission. Do not ask again
   for routine commit or push permission. Respect platform approval controls;
   if automatic review rejects publication, state its reason and do not bypass it.
7. Report local integration commit(s), successful push or precise blockage,
   remaining limitations and the next ready prompt(s). Stop if a defect requires
   implementation repair; send a bounded repair description to the owning
   session only if the owner has asked you to communicate with that session.

Worker source recipes and versioned evidence travel through Git; raw GLBs,
packed Blender working masters, ignored builds and model dependencies do not.
Verify dependent sessions can actually read the absolute local handoff path or
arrange an explicitly scoped verified transfer; do not pretend a clone has it.
Read-only access to peer worktrees is fine; do not modify their live files.

Do not start new sessions or work on additional slices merely because this
prompt lists them. Provide ready copyable prompts for the owner. G2 must review
G1 independently; final normal-world rollout is beyond the isolated G1 pilot.
Report implementation, checks, limitations, local commit and remote publication
separately, with actual media visible in chat when it helps the review.
```
