# Security Review - thoor.tech (pthoor.github.io)

**Date:** 2026-03-07
**Scope:** Full codebase security review of the Jekyll-based GitHub Pages site

---

## Executive Summary

The site demonstrates **strong security practices overall**, particularly in CI/CD pipeline configuration, supply chain protections, and XSS prevention. A few medium and low-severity findings are noted below with recommended remediations.

**Overall Risk Level: LOW**

---

## Findings

### FINDING 1: Missing Subresource Integrity (SRI) on Lunr.js CDN Script
**Severity: MEDIUM**
**Location:** `_layouts/default.html:267`

The Lunr.js library is loaded from jsDelivr CDN without an `integrity` attribute or `crossorigin` attribute:
```javascript
s.src = 'https://cdn.jsdelivr.net/npm/lunr@2.3.9/lunr.min.js';
```

The Mermaid script on line 322 correctly uses SRI (`integrity="sha384-..."` and `crossorigin="anonymous"`), but Lunr.js does not. If the CDN were compromised, arbitrary JavaScript could execute in users' browsers.

**Recommendation:** Add `integrity` and `crossorigin="anonymous"` attributes to the dynamically created script element:
```javascript
s.integrity = 'sha384-<hash>';
s.crossOrigin = 'anonymous';
```

---

### FINDING 2: innerHTML Used with User-Influenced Search Query Display
**Severity: LOW**
**Location:** `_layouts/default.html:240, 260`

The search results are rendered via `innerHTML`. However, this is **mitigated** by the `escHtml()` function (line 226-228) which properly escapes `&`, `<`, `>`, and `"` before insertion. All user-controlled data (query text, titles, tags, excerpts, dates, URLs) passes through `escHtml()` before being placed into the HTML string.

**Status:** Adequately mitigated. The escaping function covers the necessary characters for HTML context injection prevention.

---

### FINDING 3: .env Files Not in .gitignore
**Severity: LOW**
**Location:** `.gitignore`

The `.gitignore` file does not explicitly exclude `.env` files. While no `.env` files currently exist in the repository, adding this exclusion would prevent accidental commits of environment files containing secrets.

**Recommendation:** Add to `.gitignore`:
```
.env
.env.*
```

---

### FINDING 4: Google Analytics Tracking ID Exposed in Config
**Severity: INFORMATIONAL**
**Location:** `_config.yml:46`

The Google Analytics tracking ID (`G-WZZHMWX8JQ`) is in the repository config. This is **expected behavior** -- GA tracking IDs are inherently public (they appear in the page source sent to every visitor). The `anonymize_ip: true` setting is correctly enabled, which is good for GDPR compliance.

**Status:** No action required.

---

### FINDING 5: Blog Posts Reference API Keys/Tokens in Tutorial Content
**Severity: INFORMATIONAL**
**Location:** Various `_posts/*.md` files

Several blog posts discuss Azure access tokens, API keys, and credentials as part of tutorial/educational content. These are **instructional examples**, not actual secrets. No real credentials were found committed to the repository.

**Status:** No action required.

---

## Positive Security Practices Observed

### CI/CD Pipeline Security (EXCELLENT)
- **Pinned action versions with SHA hashes** in `.github/workflows/jekyll.yml` -- prevents supply chain attacks via tag manipulation
- **Minimal permissions** (`contents: read`, `pages: write`, `id-token: write`) -- follows principle of least privilege
- **`persist-credentials: false`** on checkout -- prevents credential leakage
- **Concurrency controls** prevent race conditions in deployments
- **Timeout limits** (10 min) prevent runaway builds
- **PR protection** via `bad-pr.yml` workflow -- auto-closes suspicious PRs from non-owners

### Supply Chain Security (GOOD)
- **Dependabot** configured for GitHub Actions updates (`.github/dependabot.yml`)
- All workflow actions pinned to specific commit SHAs
- Ruby dependencies use version constraints in Gemfile

### XSS Prevention (GOOD)
- Jekyll's `| escape` filter used consistently for user-controlled output in templates (titles, tags)
- Custom `escHtml()` function properly sanitizes search output
- Mermaid configured with `securityLevel: 'strict'`
- No `eval()`, `document.write()`, or other dangerous patterns

### Link Security (GOOD)
- All external links use `rel="noopener noreferrer"` and `target="_blank"` correctly
- Social sharing links properly escape page titles and URLs via `uri_escape`

### Content Security (GOOD)
- Fonts are self-hosted (no external font CDN dependency)
- Site uses HTTPS throughout (`url: "https://thoor.tech"`)
- Custom domain configured via CNAME

### Privacy (GOOD)
- Google Analytics has `anonymize_ip: true` enabled

---

## Recommendations Summary

| # | Finding | Severity | Effort | Action |
|---|---------|----------|--------|--------|
| 1 | Missing SRI on Lunr.js CDN load | Medium | Low | Add integrity + crossorigin attributes |
| 3 | .env not in .gitignore | Low | Trivial | Add `.env` and `.env.*` to .gitignore |

---

## Out of Scope

- Server-side GitHub Pages infrastructure security
- DNS/TLS configuration for thoor.tech
- Content accuracy of blog posts
- Accessibility audit (though good `aria-*` usage was noted)
