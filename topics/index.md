---
layout: page
title: "Topics"
permalink: /topics/
---

<div class="topics-grid" role="list" style="margin-top:1.5rem">
{% for topic in site.topics %}
  {% assign topic_count = 0 %}
  {% for post in site.posts %}
    {% assign matched = false %}
    {% for ttag in topic.tags %}
      {% unless matched %}
        {% for ptag in post.tags %}
          {% if ptag == ttag %}{% assign matched = true %}{% break %}{% endif %}
        {% endfor %}
      {% endunless %}
    {% endfor %}
    {% if matched %}{% assign topic_count = topic_count | plus: 1 %}{% endif %}
  {% endfor %}

  <a href="{{ '/topics/' | append: topic.slug | append: '/' | relative_url }}"
     class="topic-card topic-card--{{ topic.color | escape }}"
     role="listitem">
    <span class="topic-accent" aria-hidden="true"></span>
    <span class="topic-icon" aria-hidden="true">
      {% include icons/topic.html icon=topic.icon %}
    </span>
    <h3 class="topic-name">{{ topic.name | escape }}</h3>
    <p class="topic-desc">{{ topic.description | escape }}</p>
    <div class="topic-footer">
      <span class="topic-count">{{ topic_count }} post{% if topic_count != 1 %}s{% endif %}</span>
      <span class="topic-arrow" aria-hidden="true">&rarr;</span>
    </div>
  </a>
{% endfor %}
</div>
