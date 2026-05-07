Run the resolver to accept both sides of any merge conflict markers in the repo.

Usage (from repository root):

```powershell
python .\scripts\resolve_merge_conflicts.py .
```

Then review changes, add and commit:

```powershell
git add -A
git commit -m "chore: auto-resolve merge conflicts (keep both sides)"
```

Backups: For every modified file a `.orig-conflict` backup is created containing the original content before changes.

Caveats:
- The script keeps both sides for every conflict block. You should manually review files that may need semantic reconciliation (e.g., duplicate widget declarations, duplicated imports).
- Run tests or `flutter analyze` after resolving to catch remaining issues.
