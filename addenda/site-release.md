<!-- ADDENDUM-START: site-release (optional - apply only when the project publishes live pages) -->

## Site Release

For projects that publish public pages, these four contracts apply:

| Contract | Requirement |
|----------|-------------|
| Copy-artifact sync | Generated or vendored page content is written only by a named checked-in sync script, deriving from a named upstream and a pinned commit |
| Registration is two halves | A new page or project ships its content entry in the overview AND its navigation entries; verification greps both links in the built output |
| Fact traceability | Facts about upstream projects cite their commit; repeated facts derive from one named ledger file, generated not hand-copied |
| Deploy gate | Publishing is an explicit local script with a post-deploy probe asserting served content matches the build; each deploy run needs the owner's explicit approval |

<!-- ADDENDUM-END -->
