---
layout: page
title: Projects
permalink: /my_pages/projects/
---

<div id="project-list">
  {% if site.projects %}
    {% assign sorted_projects = site.projects | sort: 'date' | reverse %}
    {% for project in sorted_projects %}
    <article class="card-wrapper">
      <div class="card post-preview flex-md-row-reverse">
        {% if project.image %}
        <a href="{{ project.url | relative_url }}">
          <div class="post-image">
            <img src="{{ project.image }}" alt="{{ project.title }}" loading="lazy">
          </div>
        </a>
        {% endif %}
        <div class="card-body d-flex flex-column">
          <h1 class="card-title my-2 mt-md-0">
            <a href="{{ project.url | relative_url }}">{{ project.title }}</a>
          </h1>
          <div class="post-meta flex-grow-1 text-muted text-small">
            <time datetime="{{ project.date | date_to_xmlschema }}">{{ project.date | date: site.data.locales[site.lang].date_format | default: '%Y-%m-%d' }}</time>
            {% if project.categories %}
              <span class="categories">
                {% for category in project.categories %}
                  <a href="{{ '/categories/' | relative_url }}{{ category | slugify }}">{{ category }}</a>{% unless forloop.last %}, {% endunless %}
                {% endfor %}
              </span>
            {% endif %}
          </div>
          {% if project.excerpt %}
          <div class="post-content">
            <p>{{ project.excerpt | strip_html | truncatewords: 30 }}</p>
          </div>
          {% endif %}
          <div class="post-meta flex-grow-1 text-muted text-small">
            <a href="{{ project.url | relative_url }}" class="read-more">Read More →</a>
          </div>
        </div>
      </div>
    </article>
    {% endfor %}
  {% else %}
    <p>No projects available yet. Check back soon!</p>
  {% endif %}
</div>

