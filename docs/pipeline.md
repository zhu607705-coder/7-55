# Collaboration Pipeline

## Branches

- `main`: stable demo only
- `dev`: daily integration
- `feat/{scene-or-module}-{short-name}`: feature branches
- `fix/{issue-id}-{short-name}`: bug fixes
- `docs/{topic}`: documentation-only changes

## Commit Examples

```bash
feat(P06): add cellular-only tiyi entry
fix(P11): block check-in submit when network is cellular
asset(P03): add avatar key puzzle sprites
dialogue(P02): add Xiaoying code hidden subtitle
docs(framework): update GameState flags
qa(smoke): add P0 full-path checklist
```

## PR Checklist

- Local app starts.
- `npm test -- --run` passes.
- `npm run typecheck` passes.
- P0 smoke steps related to the change pass.
- New state fields, events, assets, and dialogue are documented.
- Scene README is updated.
