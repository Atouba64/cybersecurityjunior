---
layout: default
icon: fas fa-stream
order: 1
---

{% include lang.html %}

{% assign all_posts = site.posts | where_exp: 'item', 'item.hidden != true' %}

<!-- Posts Data for JavaScript -->
<script type="application/json" id="posts-data">
[
  {% for post in all_posts %}
  {
    "title": {{ post.title | jsonify }},
    "url": {{ post.url | relative_url | jsonify }},
    "date": "{{ post.date | date: '%Y-%m-%d' }}",
    "categories": {{ post.categories | jsonify }},
    "tags": {{ post.tags | jsonify }},
    "excerpt": {{ post.excerpt | default: post.content | strip_html | truncate: 200 | jsonify }},
    "image": {% if post.image %}{{ post.image | jsonify }}{% else %}null{% endif %}
  }{% unless forloop.last %},{% endunless %}
  {% endfor %}
]
</script>

<div class="flex-grow-1 px-xl-1">
  <!-- Compact Filter Bar -->
  <div class="mb-4">
    <div class="card mb-3">
      <div class="card-body p-3">
        <!-- Top Row: Search and Sort -->
        <div class="row g-2 mb-3">
          <div class="col-md-8">
            <div class="input-group input-group-sm">
              <span class="input-group-text">
                <i class="fas fa-search"></i>
              </span>
              <input 
                type="text" 
                id="search-input" 
                class="form-control" 
                placeholder="Search posts..."
                onkeyup="filterPosts()"
              >
            </div>
          </div>
          <div class="col-md-4 d-flex align-items-center gap-2">
            <label class="form-label mb-0 small text-muted">Sort:</label>
            <select id="sort-select" class="form-select form-select-sm" onchange="sortPosts()">
              <option value="newest">Newest</option>
              <option value="oldest">Oldest</option>
              <option value="title-asc">A-Z</option>
              <option value="title-desc">Z-A</option>
              <option value="category">Category</option>
            </select>
            <span class="badge bg-secondary" id="results-count"></span>
          </div>
        </div>

        <!-- Categories Filter - Expandable Dropdown Style -->
        <div class="mb-2">
          <button 
            class="category-trigger" 
            type="button"
            onclick="toggleCategoryPanel()"
            id="category-trigger"
          >
            <div class="d-flex align-items-center justify-content-between w-100">
              <div class="d-flex align-items-center flex-wrap">
                <i class="fas fa-folder me-2"></i>
                <span class="me-2">Categories</span>
                <span class="badge bg-primary category-badge" id="category-count" style="display: none;">0</span>
              </div>
              <i class="fas fa-chevron-down trigger-icon" id="category-icon"></i>
            </div>
          </button>
          <div class="filter-panel category-panel" id="category-panel" style="display: none;">
            <div class="category-pills" id="category-filters">
              <button 
                class="category-pill active" 
                onclick="toggleCategoryFilter('all')"
                data-category="all"
              >
                All Categories
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
                class="category-pill" 
                onclick="toggleCategoryFilter('{{ category }}')"
                data-category="{{ category }}"
              >
                {{ category }}
              </button>
              {% endfor %}
            </div>
          </div>
        </div>

        <!-- Tags Filter - Expandable Cloud Style -->
        <div class="mb-2">
          <button 
            class="tag-trigger" 
            type="button"
            onclick="toggleTagPanel()"
            id="tag-trigger"
          >
            <div class="d-flex align-items-center justify-content-between w-100">
              <div class="d-flex align-items-center flex-wrap">
                <i class="fas fa-tags me-2"></i>
                <span class="me-2">Tags</span>
                <span class="badge bg-secondary tag-badge" id="tag-count" style="display: none;">0</span>
              </div>
              <i class="fas fa-chevron-down trigger-icon" id="tag-icon"></i>
            </div>
          </button>
          <div class="filter-panel tag-panel" id="tag-panel" style="display: none;">
            <div class="tag-cloud" id="tag-filters">
              {% assign all_tags = '' | split: '' %}
              {% for post in all_posts %}
                {% for tag in post.tags %}
                  {% unless all_tags contains tag %}
                    {% assign all_tags = all_tags | push: tag %}
                  {% endunless %}
                {% endfor %}
              {% endfor %}
              {% assign sorted_tags = all_tags | sort %}
              {% for tag in sorted_tags %}
              <button 
                class="tag-item" 
                onclick="toggleTagFilter('{{ tag }}')"
                data-tag="{{ tag }}"
              >
                #{{ tag }}
              </button>
              {% endfor %}
            </div>
          </div>
        </div>

        <!-- Active Filters (compact) -->
        <div id="active-filters" class="mt-2 d-none">
          <div class="d-flex flex-wrap align-items-center gap-1">
            <small class="text-muted">Active:</small>
            <span id="active-filters-list"></span>
            <button class="btn btn-sm btn-link text-danger p-0" onclick="clearAllFilters()" style="font-size: 0.75rem;">
              <i class="fas fa-times"></i> Clear
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Posts Container -->
  <div id="post-list" class="flex-grow-1">
    <!-- Posts will be dynamically loaded here -->
  </div>

  <!-- No Results Message -->
  <div id="no-results" class="text-center py-5 d-none">
    <i class="fas fa-search fa-3x text-muted mb-3"></i>
    <p class="text-muted">No posts found matching your filters.</p>
    <button class="btn btn-outline-primary btn-sm" onclick="clearAllFilters()">Clear Filters</button>
  </div>
</div>

<script>
(function() {
  // Get posts data from JSON
  const postsDataScript = document.getElementById('posts-data');
  if (!postsDataScript) {
    console.error('Posts data script not found');
    return;
  }
  
  let allPosts = JSON.parse(postsDataScript.textContent);
  let filteredPosts = [...allPosts];
  let selectedCategories = new Set(['all']);
  let selectedTags = new Set();
  let searchQuery = '';
  let sortBy = 'newest';

  // Initialize
  document.addEventListener('DOMContentLoaded', function() {
    renderPosts();
    updateResultsCount();
    updateFilterCounts();
  });

  // Update filter counts
  function updateFilterCounts() {
    const categoryCount = selectedCategories.has('all') ? 0 : selectedCategories.size;
    const tagCount = selectedTags.size;
    
    const categoryBadge = document.getElementById('category-count');
    const tagBadge = document.getElementById('tag-count');
    
    if (categoryBadge) {
      categoryBadge.textContent = categoryCount;
      categoryBadge.style.display = categoryCount > 0 ? 'inline' : 'none';
    }
    
    if (tagBadge) {
      tagBadge.textContent = tagCount;
      tagBadge.style.display = tagCount > 0 ? 'inline' : 'none';
    }
  }

  // Toggle category filter
  window.toggleCategoryFilter = function(category) {
    const button = document.querySelector(`[data-category="${category}"]`);
    
    if (category === 'all') {
      selectedCategories.clear();
      selectedCategories.add('all');
      document.querySelectorAll('[data-category]').forEach(btn => {
        btn.classList.remove('active');
      });
      button.classList.add('active');
    } else {
      selectedCategories.delete('all');
      const allBtn = document.querySelector('[data-category="all"]');
      if (allBtn) allBtn.classList.remove('active');
      
      if (selectedCategories.has(category)) {
        selectedCategories.delete(category);
        button.classList.remove('active');
      } else {
        selectedCategories.add(category);
        button.classList.add('active');
      }
      
      if (selectedCategories.size === 0) {
        selectedCategories.add('all');
        const allBtn = document.querySelector('[data-category="all"]');
        if (allBtn) allBtn.classList.add('active');
      }
    }
    
    updateFilterCounts();
    filterPosts();
  };

  // Toggle tag filter
  window.toggleTagFilter = function(tag) {
    const button = document.querySelector(`[data-tag="${tag}"]`);
    
    if (selectedTags.has(tag)) {
      selectedTags.delete(tag);
      button.classList.remove('active');
    } else {
      selectedTags.add(tag);
      button.classList.add('active');
    }
    
    updateFilterCounts();
    filterPosts();
  };

  // Filter posts
  window.filterPosts = function() {
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
      searchQuery = searchInput.value.toLowerCase();
    }
    
    filteredPosts = allPosts.filter(post => {
      // Category filter
      if (!selectedCategories.has('all')) {
        const postCategories = post.categories || [];
        const hasSelectedCategory = Array.from(selectedCategories).some(cat => 
          postCategories.includes(cat)
        );
        if (!hasSelectedCategory) return false;
      }
      
      // Tag filter
      if (selectedTags.size > 0) {
        const postTags = post.tags || [];
        const hasSelectedTag = Array.from(selectedTags).some(tag => 
          postTags.includes(tag)
        );
        if (!hasSelectedTag) return false;
      }
      
      // Search filter
      if (searchQuery) {
        const searchableText = (
          post.title + ' ' + 
          post.excerpt + ' ' + 
          (post.tags || []).join(' ') + ' ' +
          (post.categories || []).join(' ')
        ).toLowerCase();
        
        if (!searchableText.includes(searchQuery)) return false;
      }
      
      return true;
    });
    
    sortPosts();
    renderPosts();
    updateResultsCount();
    updateActiveFilters();
  };

  // Sort posts
  window.sortPosts = function() {
    const sortSelect = document.getElementById('sort-select');
    if (sortSelect) {
      sortBy = sortSelect.value;
    }
    
    filteredPosts.sort((a, b) => {
      switch(sortBy) {
        case 'newest':
          return new Date(b.date) - new Date(a.date);
        case 'oldest':
          return new Date(a.date) - new Date(b.date);
        case 'title-asc':
          return a.title.localeCompare(b.title);
        case 'title-desc':
          return b.title.localeCompare(a.title);
        case 'category':
          const catA = (a.categories || [])[0] || '';
          const catB = (b.categories || [])[0] || '';
          return catA.localeCompare(catB) || a.title.localeCompare(b.title);
        default:
          return 0;
      }
    });
    
    renderPosts();
  };

  // Render posts
  function renderPosts() {
    const container = document.getElementById('post-list');
    const noResults = document.getElementById('no-results');
    
    if (!container) {
      console.error('Post list container not found');
      return;
    }
    
    if (filteredPosts.length === 0) {
      container.innerHTML = '';
      if (noResults) noResults.classList.remove('d-none');
      return;
    }
    
    if (noResults) noResults.classList.add('d-none');
    container.innerHTML = filteredPosts.map(post => {
      const date = new Date(post.date);
      const formattedDate = date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      });
      
      const categories = (post.categories || []).map(cat => 
        `<span class="badge bg-primary me-1">${cat}</span>`
      ).join('');
      
      const tags = (post.tags || []).slice(0, 3).map(tag => 
        `<span class="badge bg-secondary me-1">#${tag}</span>`
      ).join('');
      
      const imageHtml = post.image ? 
        `<div class="col-md-5">
          <img src="${post.image}" alt="${post.title}" class="w-100 h-100 object-fit-cover rounded-start">
        </div>` : '';
      
      const cardBodyCol = post.image ? '7' : '12';
      
      return `
        <article class="card-wrapper card mb-4">
          <a href="${post.url}" class="post-preview row g-0 flex-md-row-reverse text-decoration-none">
            ${imageHtml}
            <div class="col-md-${cardBodyCol}">
              <div class="card-body d-flex flex-column">
                <h1 class="card-title my-2 mt-md-0">${post.title}</h1>
                <div class="card-text content mt-0 mb-3">
                  <p>${post.excerpt}</p>
                </div>
                <div class="post-meta flex-grow-1 d-flex flex-column">
                  <div class="mb-2">
                    ${categories}
                    ${tags}
                    ${(post.tags || []).length > 3 ? `<span class="badge bg-light text-dark">+${(post.tags || []).length - 3} more</span>` : ''}
                  </div>
                  <div class="d-flex justify-content-between align-items-end">
                    <div class="text-muted small">
                      <i class="far fa-calendar fa-fw"></i>
                      ${formattedDate}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </a>
        </article>
      `;
    }).join('');
  }

  // Update results count
  function updateResultsCount() {
    const countEl = document.getElementById('results-count');
    if (!countEl) return;
    
    const total = allPosts.length;
    const filtered = filteredPosts.length;
    
    countEl.textContent = `${filtered}${filtered !== total ? '/' + total : ''}`;
  }

  // Update active filters display
  function updateActiveFilters() {
    const activeFiltersEl = document.getElementById('active-filters');
    const activeFiltersListEl = document.getElementById('active-filters-list');
    
    if (!activeFiltersEl || !activeFiltersListEl) return;
    
    const activeFilters = [];
    
    if (!selectedCategories.has('all') && selectedCategories.size > 0) {
      activeFilters.push(...Array.from(selectedCategories).map(cat => 
        `<span class="badge bg-primary">${cat}</span>`
      ));
    }
    
    if (selectedTags.size > 0) {
      activeFilters.push(...Array.from(selectedTags).map(tag => 
        `<span class="badge bg-secondary">#${tag}</span>`
      ));
    }
    
    if (searchQuery) {
      activeFilters.push(`<span class="badge bg-info">"${searchQuery}"</span>`);
    }
    
    if (activeFilters.length > 0) {
      activeFiltersListEl.innerHTML = activeFilters.join('');
      activeFiltersEl.classList.remove('d-none');
    } else {
      activeFiltersEl.classList.add('d-none');
    }
  }

  // Clear all filters
  window.clearAllFilters = function() {
    selectedCategories.clear();
    selectedCategories.add('all');
    selectedTags.clear();
    searchQuery = '';
    
    const searchInput = document.getElementById('search-input');
    if (searchInput) searchInput.value = '';
    
    const sortSelect = document.getElementById('sort-select');
    if (sortSelect) sortSelect.value = 'newest';
    sortBy = 'newest';
    
    document.querySelectorAll('[data-category]').forEach(btn => {
      btn.classList.remove('active');
    });
    const allBtn = document.querySelector('[data-category="all"]');
    if (allBtn) allBtn.classList.add('active');
    
    document.querySelectorAll('.tag-item').forEach(btn => {
      btn.classList.remove('active');
    });
    
    updateFilterCounts();
    filterPosts();
  };

  // Toggle category panel
  window.toggleCategoryPanel = function() {
    const panel = document.getElementById('category-panel');
    const icon = document.getElementById('category-icon');
    const trigger = document.getElementById('category-trigger');
    
    if (panel.style.display === 'none') {
      panel.style.display = 'block';
      icon.classList.remove('fa-chevron-down');
      icon.classList.add('fa-chevron-up');
      trigger.classList.add('active');
    } else {
      panel.style.display = 'none';
      icon.classList.remove('fa-chevron-up');
      icon.classList.add('fa-chevron-down');
      trigger.classList.remove('active');
    }
  };

  // Toggle tag panel
  window.toggleTagPanel = function() {
    const panel = document.getElementById('tag-panel');
    const icon = document.getElementById('tag-icon');
    const trigger = document.getElementById('tag-trigger');
    
    if (panel.style.display === 'none') {
      panel.style.display = 'block';
      icon.classList.remove('fa-chevron-down');
      icon.classList.add('fa-chevron-up');
      trigger.classList.add('active');
    } else {
      panel.style.display = 'none';
      icon.classList.remove('fa-chevron-up');
      icon.classList.add('fa-chevron-down');
      trigger.classList.remove('active');
    }
  };
})();
</script>

<style>
/* Category and Tag Triggers - Same Button Style */
.category-trigger,
.tag-trigger {
  width: 100%;
  padding: 0.9rem 1rem;
  border: 1px solid #d4a574;
  background: var(--main-bg);
  color: var(--main-text-color);
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: left;
}

.category-trigger:hover,
.tag-trigger:hover {
  border-color: #c8955f;
  background: rgba(212, 165, 116, 0.05);
}

.category-trigger.active,
.tag-trigger.active {
  border-color: #d4a574;
  background: rgba(212, 165, 116, 0.08);
  color: var(--main-text-color);
}

.category-trigger .trigger-icon,
.tag-trigger .trigger-icon {
  transition: transform 0.2s ease;
  font-size: 0.75rem;
}

.category-trigger.active .trigger-icon,
.tag-trigger.active .trigger-icon {
  transform: rotate(180deg);
}

/* Category and Tag Panels - Same Panel Style */
.category-panel,
.tag-panel {
  margin-top: 0.5rem;
  padding: 1rem;
  background: var(--main-bg);
  border: 1px solid var(--main-border-color);
  border-radius: 8px;
  animation: slideDown 0.2s ease;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.category-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.category-pill {
  padding: 0.5rem 1.2rem;
  border: 1.5px solid var(--main-border-color);
  background: var(--main-bg);
  color: var(--main-text-color);
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.category-pill:hover {
  border-color: var(--bs-primary);
  background: rgba(var(--bs-primary-rgb), 0.1);
  color: var(--bs-primary);
  transform: translateY(-1px);
}

.category-pill.active {
  background: var(--bs-primary);
  border-color: var(--bs-primary);
  color: white;
  box-shadow: 0 2px 8px rgba(var(--bs-primary-rgb), 0.3);
}


.tag-cloud {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  max-height: 200px;
  overflow-y: auto;
  padding: 0.5rem;
}

.tag-item {
  padding: 0.4rem 0.9rem;
  border: none;
  background: linear-gradient(135deg, rgba(var(--bs-secondary-rgb), 0.15), rgba(var(--bs-secondary-rgb), 0.08));
  color: var(--main-text-color);
  border-radius: 15px;
  font-size: 0.75rem;
  font-weight: 400;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
  border: 1px solid transparent;
}

.tag-item:hover {
  background: linear-gradient(135deg, rgba(var(--bs-secondary-rgb), 0.25), rgba(var(--bs-secondary-rgb), 0.15));
  border-color: var(--bs-secondary);
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(var(--bs-secondary-rgb), 0.2);
}

.tag-item.active {
  background: linear-gradient(135deg, var(--bs-secondary), rgba(var(--bs-secondary-rgb), 0.85));
  color: white;
  border-color: var(--bs-secondary);
  box-shadow: 0 2px 8px rgba(var(--bs-secondary-rgb), 0.4);
  font-weight: 500;
}

#post-list .card-wrapper {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

#post-list .card-wrapper:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
}

.tag-cloud::-webkit-scrollbar {
  width: 6px;
}

.tag-cloud::-webkit-scrollbar-track {
  background: transparent;
  border-radius: 3px;
}

.tag-cloud::-webkit-scrollbar-thumb {
  background: var(--main-border-color);
  border-radius: 3px;
}

.tag-cloud::-webkit-scrollbar-thumb:hover {
  background: var(--sidebar-active-color);
}

.badge {
  font-size: 0.7rem;
  padding: 0.25em 0.5em;
}

.category-badge,
.tag-badge {
  margin-left: 0.5rem;
  flex-shrink: 0;
  line-height: 1.2;
  vertical-align: middle;
}

#results-count {
  font-size: 0.75rem;
  white-space: nowrap;
}
</style>
