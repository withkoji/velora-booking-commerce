# VELORA – WORKBRIDGE

Installable mobile and desktop web app for wellness, housing and career workflows.

## Run

From this directory: `python3 -m http.server 8080 --directory dist`.
Open `http://localhost:8080`. Serve dist at the origin root because the app uses root-relative paths. HTTPS is required for installation away from localhost.

## Connected destinations

- [VELORA health and wellbeing](https://velorabysj.zite.so/)
- [VIVIA rental services](https://viviarentalhomes.zite.so)
- [WORKBRIDGE opportunities](https://workbridge.zite.so)

Personal checklists are browser-local. Portal links do not sync bookings or applications. GitHub, Zite and Google live integrations remain unimplemented; installed ChatGPT plugins are not automatically available inside this app.

## Related code and history

RELATED_SOURCES.json pins the source branches, commit IDs, file blob IDs and links. The transfer branch inherits current booking-commerce history plus the sandbox guard candidate from PR #44. Older Stripe branches and the foundation branch are references, not replacement runtime implementations. Do not merge them wholesale: older snapshots remove later security/regression work. No new payment execution path is introduced.

The OpenAPI profile and remote-job search work remain owned by their original repositories. GitHub issues, PRs and comments stay there and are linked, not copied as fabricated new objects.

## Repository transfer

Target: `withkoji/velora-workbridge` (proposed; remote creation pending authenticated GitHub repository creation).

The reviewable transfer branch is `integration/velora-workbridge-hub` in the existing repository. Create the new private repository, then push this branch as main or import its history. Preserve the historical branch names as archive refs only after review; never force-push an existing destination. Update deployment bindings explicitly after transfer. The current ChatGPT Site retains its existing identity and source repository.

Do not copy credentials, local runtime state or the existing Site hosting identity into a new independently deployed Site. Configure deployment secrets outside Git.

## Verification

JavaScript syntax, manifest icon paths and the three portal destinations are checked by ../../scripts/validate-workbridge.mjs. CI also runs inherited Stripe receiver regressions. Neither proves live payments, live plugin access or job/property authenticity.
