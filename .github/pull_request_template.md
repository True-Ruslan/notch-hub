## Summary

- 

## Why / behavior contract

- 

## TDD evidence

- [ ] RED observed for the intended behavior (describe failing test/result below)
- [ ] GREEN observed after the production change
- [ ] Refactor, if any, kept the full suite green

RED evidence:

- 

## Validation

- [ ] `swift format lint --recursive --strict Sources Tests Package.swift`
- [ ] `swift build`
- [ ] `swift test --parallel --enable-code-coverage`
- [ ] `./scripts/build-dmg.sh`
- [ ] bundle/code-signature/DMG integrity checks

## Documentation and release hygiene

- [ ] `CHANGELOG.md` updated, or change is not notable
- [ ] `docs/PROJECT_STATE.md` updated if project/acceptance state changed
- [ ] roadmap/architecture/testing docs updated when their contract changed
- [ ] `VERSION` change is intentional, or version remains correct

## Manual checks

- [ ] Not required
- [ ] Required and documented below using IDs from `docs/TESTING.md`

Results / pending checks:

- 
