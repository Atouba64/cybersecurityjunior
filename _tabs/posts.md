---
layout: page
title: Posts
icon: fas fa-stream
order: 2
permalink: /posts/
hide_title: true
---

{% include lang.html %}
{% assign lang = page.lang | default: site.lang %}
{% assign all_posts = site.posts | where_exp: 'item', 'item.hidden != true' %}

<!-- Filter & Sort Controls -->
<div class="mb-4">
  <button 
    class="btn btn-sm btn-outline-primary d-flex align-items-center gap-2" 
    type="button" 
    data-bs-toggle="collapse" 
    data-bs-target="#filterSortPanel" 
    aria-expanded="false" 
    aria-controls="filterSortPanel"
    id="filterSortToggle"
  >
    <i class="fas fa-filter"></i>
    <span>Filter & Sort</span>
    <span class="badge bg-primary ms-1" id="activeFilterCount" style="display: none;">0</span>
    <i class="fas fa-chevron-down ms-auto" id="filterSortIcon"></i>
  </button>
  
  <div class="collapse mt-3" id="filterSortPanel">
    <div class="card">
      <div class="card-body">
        <!-- Search -->
        <div class="mb-3">
          <label class="form-label small text-muted mb-2">Search</label>
          <div class="input-group input-group-sm">
            <span class="input-group-text">
              <i class="fas fa-search"></i>
            </span>
            <input 
              type="text" 
              id="postSearch" 
              class="form-control" 
              placeholder="Search posts by title, content, or tags..."
            >
          </div>
        </div>

        <!-- Sort -->
        <div class="mb-3">
          <label class="form-label small text-muted mb-2">Sort By</label>
          <select id="sortSelect" class="form-select form-select-sm">
            <option value="newest">Newest First</option>
            <option value="oldest">Oldest First</option>
            <option value="title-asc">Title A-Z</option>
            <option value="title-desc">Title Z-A</option>
            <option value="category">Category</option>
          </select>
        </div>

        <!-- Categories -->
        <div class="mb-3">
          <label class="form-label small text-muted mb-2">Categories</label>
          <div class="d-flex flex-wrap gap-2" id="categoryFilters">
            <button 
              class="btn btn-sm btn-outline-secondary filter-chip active" 
              data-filter="category" 
              data-value="all"
              onclick="toggleFilter(this, 'category', 'all')"
            >
              All
            </button>
            {% assign all_categories = '' | split: '' %}
            {% for post in all_posts %}
              {% for category in post.categories %}
                {% unless all_categories contains category %}
                  {% assign all_categories = all_categories | push: category %}
                {% endunless %}
              {% endfor %}
            {% endfor %}
            {% for category in all_categories %}
            <button 
              class="btn btn-sm btn-outline-secondary filter-chip" 
              data-filter="category" 
              data-value="{{ category }}"
              onclick="toggleFilter(this, 'category', '{{ category }}')"
            >
              {{ category }}
            </button>
            {% endfor %}
          </div>
        </div>

        <!-- Tags -->
        <div class="mb-3">
          <label class="form-label small text-muted mb-2">Tags</label>
          <div class="d-flex flex-wrap gap-2" id="tagFilters">
            {% assign all_tags = '' | split: '' %}
            {% for post in all_posts %}
              {% for tag in post.tags %}
                {% unless all_tags contains tag %}
                  {% assign all_tags = all_tags | push: tag %}
                {% endunless %}
              {% endfor %}
            {% endfor %}
            {% for tag in all_tags %}
            <button 
              class="btn btn-sm btn-outline-secondary filter-chip" 
              data-filter="tag" 
              data-value="{{ tag }}"
              onclick="toggleFilter(this, 'tag', '{{ tag }}')"
            >
              #{{ tag }}
            </button>
            {% endfor %}
          </div>
        </div>

        <!-- Clear Filters -->
        <div class="d-flex justify-content-end">
          <button 
            class="btn btn-sm btn-link text-decoration-none" 
            id="clearFilters"
            onclick="clearAllFilters()"
            style="display: none;"
          >
            Clear All
          </button>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Results Count -->
<div class="mb-3">
  <p class="text-muted small mb-0">
    <span id="resultsCount">{{ all_posts | size }}</span> article{{ all_posts | size | pluralize: '', 's' }}
  </p>
</div>

<!-- Posts List -->
<div id="post-list" class="flex-grow-1 px-xl-1">
  {% for post in all_posts %}
    {% assign read_minutes = post.read_time | default: post.content | number_of_words | divided_by: 200 | ceil %}
    {% if read_minutes < 1 %}
      {% assign read_minutes = 1 %}
    {% endif %}
    <article class="card-wrapper card" data-post
      data-title="{{ post.title | downcase | xml_escape }}"
      data-excerpt="{{ post.excerpt | default: post.content | strip_html | strip_newlines | truncate: 200 | downcase | xml_escape }}"
      data-categories="{{ post.categories | join: '|' | downcase }}"
      data-tags="{{ post.tags | join: '|' | downcase }}"
      data-date="{{ post.date | date: '%s' }}"
      data-read="{{ read_minutes }}">
      <a href="{{ post.url | relative_url }}" class="post-preview post-card-link">
        <div class="post-card-inner d-flex flex-column flex-md-row">
          {% if post.image %}
            {% assign src = post.image.path | default: post.image %}

            {% if post.media_subpath %}
              {% unless src contains '://' %}
                {% assign src = post.media_subpath
                  | append: '/'
                  | append: src
                  | replace: '///', '/'
                  | replace: '//', '/'
                %}
              {% endunless %}
            {% endif %}

            {% if post.image.lqip %}
              {% assign lqip = post.image.lqip %}

              {% if post.media_subpath %}
                {% unless lqip contains 'data:' %}
                  {% assign lqip = post.media_subpath
                    | append: '/'
                    | append: lqip
                    | replace: '///', '/'
                    | replace: '//', '/'
                  %}
                {% endunless %}
              {% endif %}

              {% assign lqip_attr = 'lqip="' | append: lqip | append: '"' %}
            {% endif %}

            {% assign alt = post.image.alt | xml_escape | default: 'Preview Image' %}

            <div class="post-card-image">
              <img src="{{ src }}" alt="{{ alt }}" {{ lqip_attr }}>
            </div>
          {% endif %}

          <div class="post-card-content">
            <div class="card-body d-flex flex-column">
              <h1 class="card-title my-2 mt-md-0">{{ post.title }}</h1>

              <div class="card-text content mt-0 mb-3">
                <p>{% include post-summary.html %}</p>
              </div>

              <div class="post-meta flex-grow-1 d-flex align-items-end">
                <div class="me-auto">
                  <!-- posted date -->
                  <i class="far fa-calendar fa-fw me-1"></i>
                  {% include datetime.html date=post.date lang=lang %}

                  <!-- categories -->
                  {% if post.categories.size > 0 %}
                    <i class="far fa-folder-open fa-fw me-1"></i>
                    <span class="categories">
                      {% for category in post.categories %}
                        {{ category }}
                        {%- unless forloop.last -%},{%- endunless -%}
                      {% endfor %}
                    </span>
                  {% endif %}
                </div>

                {% if post.pin %}
                  <div class="pin ms-1">
                    <i class="fas fa-thumbtack fa-fw"></i>
                    <span>{{ site.data.locales[lang].post.pin_prompt }}</span>
                  </div>
                {% endif %}
              </div>
              <!-- .post-meta -->
            </div>
            <!-- .card-body -->
          </div>
        </div>
      </a>
    </article>
  {% endfor %}
</div>
<!-- #post-list -->

<!-- No Results Message -->
<div id="no-results" class="alert alert-info d-none" role="alert">
  No posts match the current filters. Try adjusting your search or filters.
</div>

<style>
  /* Hide page title */
  .dynamic-title {
    display: none !important;
  }

  /* Filter & Sort Panel Styling - Chirpy Theme Compatible */
  #filterSortPanel .card {
    border: 1px solid var(--border-color);
    background-color: var(--card-bg);
  }

  #filterSortPanel .form-label {
    color: var(--text-muted-color);
    font-weight: 500;
  }

  #filterSortPanel .form-control,
  #filterSortPanel .form-select {
    background-color: var(--main-bg);
    border-color: var(--border-color);
    color: var(--text-color);
  }

  #filterSortPanel .form-control:focus,
  #filterSortPanel .form-select:focus {
    background-color: var(--main-bg);
    border-color: var(--sidebar-active-color);
    color: var(--text-color);
    box-shadow: 0 0 0 0.2rem rgba(var(--bs-primary-rgb), 0.25);
  }

  .filter-chip {
    transition: all 0.2s ease;
    border-radius: 0.375rem;
  }

  .filter-chip:hover {
    transform: translateY(-1px);
  }

  .filter-chip.active {
    background-color: var(--sidebar-active-color);
    border-color: var(--sidebar-active-color);
    color: var(--sidebar-active-text-color);
  }

  #filterSortToggle {
    border-color: var(--border-color);
    color: var(--text-color);
  }

  #filterSortToggle:hover {
    background-color: var(--sidebar-active-color);
    border-color: var(--sidebar-active-color);
    color: var(--sidebar-active-text-color);
  }

  #filterSortIcon {
    transition: transform 0.3s ease;
  }

  #filterSortPanel.show #filterSortIcon {
    transform: rotate(180deg);
  }

  /* Ensure visibility in both themes */
  .input-group-text {
    background-color: var(--main-bg);
    border-color: var(--border-color);
    color: var(--text-muted-color);
  }

  .btn-outline-secondary {
    border-color: var(--border-color);
    color: var(--text-color);
  }

  .btn-outline-secondary:hover {
    background-color: var(--sidebar-active-color);
    border-color: var(--sidebar-active-color);
    color: var(--sidebar-active-text-color);
  }

  .btn-link {
    color: var(--sidebar-active-color);
  }

  .btn-link:hover {
    color: var(--sidebar-active-color);
    opacity: 0.8;
  }

  /* Post Card Layout - Image on right (40%), Content on left (60%) */
  .post-card-link {
    text-decoration: none;
    color: inherit;
    display: block;
    width: 100%;
  }

  .post-card-link:hover {
    text-decoration: none;
    color: inherit;
  }

  .post-card-inner {
    width: 100%;
    display: flex;
    flex-direction: row;
    gap: 0.75rem; /* Slight space between image and content */
  }

  /* Content section - 60% width, on the left */
  .post-card-content {
    flex: 0 0 60%;
    max-width: 60%;
    min-width: 0; /* Prevent flex item from overflowing */
    order: 1; /* Ensure content appears first (left side) */
  }

  /* Image section - 40% width, on the right */
  .post-card-image {
    flex: 0 0 40%;
    max-width: 40%;
    min-width: 0;
    overflow: hidden;
    display: flex;
    align-items: stretch;
    justify-content: center;
    order: 2; /* Ensure image appears second (right side) */
    background-color: var(--main-bg, #f8f9fa);
  }

  .post-card-image img {
    width: 100%;
    height: 100%;
    min-height: 200px;
    object-fit: cover;
    display: block;
  }

  /* Ensure image container matches card height */
  .card-wrapper .post-card-inner {
    min-height: 200px;
  }

  /* When no image exists, content takes full width */
  .post-card-inner:not(:has(.post-card-image)) .post-card-content {
    flex: 0 0 100% !important;
    max-width: 100% !important;
  }

  /* Fallback for browsers that don't support :has() */
  .post-card-content:only-child {
    flex: 0 0 100% !important;
    max-width: 100% !important;
  }

  /* Mobile: stack vertically */
  @media (max-width: 767.98px) {
    .post-card-inner {
      flex-direction: column;
      gap: 0;
    }

    .post-card-content {
      flex: 0 0 100%;
      max-width: 100%;
      order: 1;
    }

    .post-card-image {
      flex: 0 0 auto;
      max-width: 100%;
      width: 100%;
      max-height: 250px;
      order: 2;
    }

    .post-card-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }

  /* Ensure card doesn't extend beyond container */
  .card-wrapper {
    overflow: hidden;
    width: 100%;
  }

  .post-card-inner {
    height: 100%;
  }

  /* Ensure consistent card height */
  .card-wrapper .card {
    height: 100%;
  }
</style>

<script>
(function() {
  'use strict';

  const posts = Array.from(document.querySelectorAll('[data-post]')).map(el => ({
    el,
    title: el.dataset.title || '',
    excerpt: el.dataset.excerpt || '',
    categories: (el.dataset.categories || '').split('|').filter(Boolean),
    tags: (el.dataset.tags || '').split('|').filter(Boolean),
    date: Number(el.dataset.date),
    read: Number(el.dataset.read || 0)
  }));

  let filteredPosts = [...posts];
  let selectedCategories = new Set(['all']);
  let selectedTags = new Set();
  let searchQuery = '';
  let sortBy = 'newest';

  // Initialize
  document.addEventListener('DOMContentLoaded', function() {
    const filterPanel = document.getElementById('filterSortPanel');
    const filterToggle = document.getElementById('filterSortToggle');
    
    if (filterPanel) {
      filterPanel.addEventListener('show.bs.collapse', function() {
        document.getElementById('filterSortIcon').style.transform = 'rotate(180deg)';
      });
      
      filterPanel.addEventListener('hide.bs.collapse', function() {
        document.getElementById('filterSortIcon').style.transform = 'rotate(0deg)';
      });
    }

    // Search input
    const searchInput = document.getElementById('postSearch');
    if (searchInput) {
      searchInput.addEventListener('input', function(e) {
        searchQuery = e.target.value.toLowerCase().trim();
        applyFilters();
      });
    }

    // Sort select
    const sortSelect = document.getElementById('sortSelect');
    if (sortSelect) {
      sortSelect.addEventListener('change', function(e) {
        sortBy = e.target.value;
        applyFilters();
      });
    }
  });

  // Toggle filter
  window.toggleFilter = function(button, type, value) {
    if (type === 'category') {
      if (value === 'all') {
        selectedCategories.clear();
        selectedCategories.add('all');
        document.querySelectorAll('[data-filter="category"]').forEach(btn => {
          btn.classList.remove('active');
        });
        button.classList.add('active');
      } else {
        selectedCategories.delete('all');
        document.querySelector('[data-filter="category"][data-value="all"]')?.classList.remove('active');
        
        if (selectedCategories.has(value)) {
          selectedCategories.delete(value);
          button.classList.remove('active');
        } else {
          selectedCategories.add(value);
          button.classList.add('active');
        }

        if (selectedCategories.size === 0) {
          selectedCategories.add('all');
          document.querySelector('[data-filter="category"][data-value="all"]')?.classList.add('active');
        }
      }
    } else if (type === 'tag') {
      if (selectedTags.has(value)) {
        selectedTags.delete(value);
        button.classList.remove('active');
      } else {
        selectedTags.add(value);
        button.classList.add('active');
      }
    }

    updateActiveFilterCount();
    applyFilters();
  };

  // Clear all filters
  window.clearAllFilters = function() {
    selectedCategories.clear();
    selectedCategories.add('all');
    selectedTags.clear();
    searchQuery = '';
    
    document.getElementById('postSearch').value = '';
    document.getElementById('sortSelect').value = 'newest';
    sortBy = 'newest';
    
    document.querySelectorAll('.filter-chip').forEach(btn => {
      btn.classList.remove('active');
    });
    document.querySelector('[data-filter="category"][data-value="all"]')?.classList.add('active');
    
    updateActiveFilterCount();
    applyFilters();
  };

  // Update active filter count
  function updateActiveFilterCount() {
    const count = (selectedCategories.has('all') ? 0 : selectedCategories.size) + selectedTags.size + (searchQuery ? 1 : 0);
    const badge = document.getElementById('activeFilterCount');
    const clearBtn = document.getElementById('clearFilters');
    
    if (badge) {
      if (count > 0) {
        badge.textContent = count;
        badge.style.display = 'inline';
      } else {
        badge.style.display = 'none';
      }
    }
    
    if (clearBtn) {
      clearBtn.style.display = count > 0 ? 'block' : 'none';
    }
  }

  // Apply filters and sort
  function applyFilters() {
    filteredPosts = posts.filter(post => {
      // Category filter
      if (!selectedCategories.has('all')) {
        const hasCategory = Array.from(selectedCategories).some(cat =>
          post.categories.some(pc => pc === cat.toLowerCase())
        );
        if (!hasCategory) return false;
      }

      // Tag filter
      if (selectedTags.size > 0) {
        const hasTag = Array.from(selectedTags).some(tag =>
          post.tags.some(pt => pt.toLowerCase() === tag.toLowerCase())
        );
        if (!hasTag) return false;
      }

      // Search filter
      if (searchQuery) {
        const searchable = (post.title + ' ' + post.excerpt + ' ' + 
          post.categories.join(' ') + ' ' + post.tags.join(' ')).toLowerCase();
        if (!searchable.includes(searchQuery)) return false;
      }

      return true;
    });

    // Sort
    filteredPosts.sort((a, b) => {
      switch(sortBy) {
        case 'newest':
          return b.date - a.date;
        case 'oldest':
          return a.date - b.date;
        case 'title-asc':
          return a.title.localeCompare(b.title);
        case 'title-desc':
          return b.title.localeCompare(a.title);
        case 'category':
          const catA = a.categories[0] || '';
          const catB = b.categories[0] || '';
          return catA.localeCompare(catB) || a.title.localeCompare(b.title);
        default:
          return 0;
      }
    });

    renderPosts();
  }

  // Render posts
  function renderPosts() {
    const container = document.getElementById('post-list');
    const noResults = document.getElementById('no-results');
    const resultsCount = document.getElementById('resultsCount');

    if (!container) return;

    if (filteredPosts.length === 0) {
      container.innerHTML = '';
      if (noResults) noResults.classList.remove('d-none');
      if (resultsCount) resultsCount.textContent = '0';
      return;
    }

    if (noResults) noResults.classList.add('d-none');
    if (resultsCount) {
      resultsCount.textContent = filteredPosts.length;
    }

    const fragment = document.createDocumentFragment();
    filteredPosts.forEach(post => {
      fragment.appendChild(post.el);
    });

    container.innerHTML = '';
    container.appendChild(fragment);
  }

  // Initial render
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyFilters);
  } else {
    applyFilters();
  }
})();
</script>
