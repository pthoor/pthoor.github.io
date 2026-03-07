# Security Review - thoor.tech (pthoor.github.io)

**Date:** 2026-03-07
**Scope:** Full codebase security review of the Jekyll-based GitHub Pages site

---

## Executive Summary

The site demonstrates **strong security practices overall**, particularly in CI/CD pipeline configuration, supply chain protections, branch protection rulesets, and XSS prevention. All identified findings have been remediated.

**Overall Risk Level: LOW**

---

## Findings

### FINDING 1: Missing Subresource Integrity (SRI) on Lunr.js CDN Script
**Severity: MEDIUM**
**Location:** `_layouts/default.html:267`
**Status: RESOLVED**

The Lunr.js library loaded from jsDelivr CDN now includes `integrity` and `crossOrigin` attributes, matching the pattern used by Mermaid.

---

### FINDING 2: innerHTML Used with User-Influenced Search Query Display
**Severity: LOW**
**Location:** `_layouts/default.html:240, 260`

The search results are rendered via `innerHTML`. However, this is **mitigated** by the `escHtml()` function (line 226-228) which properly escapes `&`, `<`, `>`, and `"` before insertion. All user-controlled data (query text, titles, tags, excerpts, dates, URLs) passes through `escHtml()` before being placed into the HTML string.

**Status:** Adequately mitigated.

---

### FINDING 3: .env Files Not in .gitignore
**Severity: LOW**
**Location:** `.gitignore`
**Status: RESOLVED**

`.env` and `.env.*` patterns have been added to `.gitignore`.

---

### FINDING 4: Unescaped Previous/Next Post Titles in Navigation
**Severity: MEDIUM**
**Location:** `_layouts/single.html:109, 115`
**Status: RESOLVED**

Post titles in previous/next navigation were rendered without the `| escape` filter, unlike the main post title. Fixed by adding `| escape` to both.

---

### FINDING 5: Unescaped Link Labels in Templates
**Severity: LOW**
**Location:** `_layouts/single.html:61`, `_includes/footer.html:21`
**Status: RESOLVED**

Link labels from navigation data and author links were not escaped. Fixed by adding `| escape` filter.

---

### FINDING 6: Unescaped Author Name/Bio in Footer and Author Bio
**Severity: LOW**
**Location:** `_includes/footer.html:5, 6, 28`, `_layouts/single.html:57, 58`
**Status: RESOLVED**

Site configuration values (`site.author.name`, `site.author.bio`) were not escaped. Fixed by adding `| escape` filter for defense-in-depth.

---

### FINDING 7: Unescaped Meta Tag Values in SEO Include
**Severity: LOW**
**Location:** `_includes/seo.html:17, 23, 37`
**Status: RESOLVED**

Author name and title values in `<meta>` tags (og:title, twitter:title, author) were not escaped. Fixed by adding `| escape` filter.

---

### FINDING 8: Google Analytics Tracking ID Exposed in Config
**Severity: INFORMATIONAL**
**Location:** `_config.yml:46`

The Google Analytics tracking ID (`G-WZZHMWX8JQ`) is in the repository config. This is **expected behavior** -- GA tracking IDs are inherently public. The `anonymize_ip: true` setting is correctly enabled for GDPR compliance.

**Status:** No action required.

---

### FINDING 9: Blog Posts Reference API Keys/Tokens in Tutorial Content
**Severity: INFORMATIONAL**
**Location:** Various `_posts/*.md` files

Several blog posts discuss Azure access tokens, API keys, and credentials as part of tutorial/educational content. These are **instructional examples**, not actual secrets.

**Status:** No action required.

---

## Positive Security Practices Observed

### Branch Protection Ruleset (EXCELLENT)
- **Main branch protected** with active enforcement and no bypass actors
- **Pull request required** with 1 approving review -- no direct pushes to main
- **Squash-only merges** enforced for clean history
- **Stale reviews dismissed** on new pushes
- **Required status checks** (`build`) with strict policy -- branch must be up-to-date
- **Branch creation/deletion/non-fast-forward protected** -- prevents force pushes and history rewriting

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
- **SRI (Subresource Integrity)** on all CDN-loaded scripts (Lunr.js, Mermaid)

### XSS Prevention (GOOD)
- Jekyll's `| escape` filter used consistently across all templates for user-controlled and config-controlled output
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

All identified issues have been remediated. No outstanding action items.

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | Missing SRI on Lunr.js CDN load | Medium | Resolved |
| 2 | innerHTML in search (mitigated by escHtml) | Low | Mitigated |
| 3 | .env not in .gitignore | Low | Resolved |
| 4 | Unescaped prev/next post titles | Medium | Resolved |
| 5 | Unescaped link labels | Low | Resolved |
| 6 | Unescaped author name/bio | Low | Resolved |
| 7 | Unescaped SEO meta tags | Low | Resolved |
| 8 | GA tracking ID in config | Informational | Expected |
| 9 | Tutorial API key references | Informational | Expected |

---

## Out of Scope

- Server-side GitHub Pages infrastructure security
- DNS/TLS configuration for thoor.tech
- Content accuracy of blog posts
- Accessibility audit (though good `aria-*` usage was noted)
