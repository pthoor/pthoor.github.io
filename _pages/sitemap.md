---
layout: page
title: "Sitemap"
permalink: /sitemap/
---

A list of all the posts and pages found on the site. For you robots out there, an [XML version]({{ "sitemap.xml" | relative_url }}) is available for digesting as well.

## Pages
{% for page in site.pages %}
{% if page.title %}
- [{{ page.title }}]({{ page.url | relative_url }})
{% endif %}
{% endfor %}

## Posts
{% for post in site.posts %}
- [{{ post.title }}]({{ post.url | relative_url }}) — {{ post.date | date: "%B %-d, %Y" }}
{% endfor %}
