 Done! The home feed endpoints are now ready with full pagination support.

  ★ Insight ─────────────────────────────────────
  Each section now has independent pagination - users can scroll through "New Restaurants" infinitely
  without affecting other sections. This decoupled approach makes the UI more responsive and the
  backend more efficient.
  ─────────────────────────────────────────────────

  ✅ Implementation Complete

  API Endpoints:

  1. Initial Home Screen Load

  GET /api/v1/restaurants/home-feed

  Response:
  {
    "advertised": {
      "title": "Highlights for you",
      "restaurants": [...],
      "total": 5
    },
    "new_restaurants": {
      "title": "New on Platform",
      "restaurants": [...],      // First 20
      "total": 85,
      "limit": 20,
      "offset": 1,
      "has_more": true
    },
    "popular": {
      "title": "Popular Near You",
      "restaurants": [...],      // First 20
      "total": 120,
      "limit": 20,
      "offset": 1,
      "has_more": true
    },
    "categories": [
      {
        "id": 1,
        "name": "Pizza",
        "restaurants": [...],    // First 6
        "total": 45,
        "limit": 6,
        "offset": 1,
        "has_more": true
      }
    ]
  }

  2. Load More (Pagination)

  GET /api/v1/restaurants/home-feed/section/{section}/{category_id?}?offset=2

  Examples:
  // Load more new restaurants (page 2)
  GET /restaurants/home-feed/section/new?offset=2

  // Load more popular restaurants (page 3)
  GET /restaurants/home-feed/section/popular?offset=3

  // Load more Pizza restaurants (page 2)
  GET /restaurants/home-feed/section/category/1?offset=2

  Response:
  {
    "section": "new",
    "restaurants": [...],
    "total": 85,
    "limit": 20,
    "offset": 2,
    "has_more": true
  }

  ---
  📱 Frontend Integration Guide

  // === INITIAL LOAD ===
  const feed = await api.get('/restaurants/home-feed');

  // Render each section
  renderAdvertised(feed.advertised);           // All ads
  renderSection('new', feed.new_restaurants);  // 20 initial
  renderSection('popular', feed.popular);      // 20 initial
  feed.categories.forEach(cat =>
    renderCategory(cat)                        // 6 each
  );

  // === INFINITE SCROLL / LOAD MORE ===
  class SectionPaginator {
    constructor(section, categoryId = null) {
      this.section = section;
      this.categoryId = categoryId;
      this.offset = 1;
      this.hasMore = true;
    }

    async loadMore() {
      if (!this.hasMore) return [];

      this.offset++;
      const url = this.categoryId
        ? `/restaurants/home-feed/section/category/${this.categoryId}?offset=${this.offset}`
        : `/restaurants/home-feed/section/${this.section}?offset=${this.offset}`;

      const response = await api.get(url);
      this.hasMore = response.has_more;
      return response.restaurants;
    }
  }

  // Usage:
  const newPaginator = new SectionPaginator('new');
  const pizzaPaginator = new SectionPaginator('category', 1);

  // On scroll or "Load More" button:
  const moreNew = await newPaginator.loadMore();
  appendToSection('new', moreNew);

  ---
  🎯 Summary

  | Endpoint                        | Purpose               | Initial Data                         |
  |---------------------------------|-----------------------|--------------------------------------|
  | home-feed                       | App launch            | 20 new + 20 popular + 6×8 categories |
  | home-feed/section/new           | Load more new         | 20 per page                          |
  | home-feed/section/popular       | Load more popular     | 20 per page                          |
  | home-feed/section/category/{id} | Load more by category | 6 per page                           |

  Your home screen is now optimized with fast initial load and smooth infinite scroll! 🚀