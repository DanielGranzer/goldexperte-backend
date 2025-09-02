# Projekt: Goldexperte

## Goal
Build a fully working **frontend system** that fetches its content from a **headless Pimcore backend** via REST API.  

- **Phase 1**: The Pimcore backend will serve data for the main website **diegoldexperten.com**.  
- **Phase 2**: A second website, **dieverlobungsringexperten.com**, will also fetch its data from Pimcore.  
  - Both websites will share a similar structure.  
  - Jewelry profiles (e.g., Goldexperten) will be centrally managed in Pimcore and exposed via the API.  

👉 **SEO and localized SEO** are the top priority, as these platforms should become the go-to hubs for:  
- Buying & selling gold  
- (Future) Engagement ring expertise  

---

## Current Status
- ✅ Frontend set up with **hardcoded data** (pages, text, images, Goldexperten profiles).  
- ✅ Pimcore backend system initialized (empty, no content yet).  

---

## Planned Features (Prioritized)

### 1. Precious Metal Data Integration
- Fetch gold/silver/platinum prices from **[metals-api.com](https://metals-api.com)**.  
- Save data in Pimcore for caching (200 API calls/month limit).  
- Provide this cached data to the Next.js frontend via REST API for relevant sections.  

### 2. Data Objects in Pimcore
- Implement all required **DataObjects** for frontend content.  
- Exact specifications will be detailed in a separate `.md` document.  

#### 2.1. Expert Profiles (Goldexperte / Verlobungsringexperte)
- Editorial team can add new expert profiles in the Pimcore admin panel.  
- Once a profile is set to **live**, Next.js ISR will generate the profile page.  
- Profile goes live automatically and is viewable on the site.  

### 3. Form Handling
- Customers can submit forms on the frontend (e.g., to request becoming a Goldexperte).  
- Submissions will appear in Pimcore as **customer requests**.  
- Workflow:  
  1. Customer submits data → receives confirmation email.  
  2. Editorial team reviews submission.  
  3. If **approved** → team contacts the customer and sets up their profile.  
  4. If **rejected** → automatic email is sent with rejection reason and optional editorial note.  

### 4. Search Functionality
- Implement **geo-based search** for finding nearby Goldexperten by city/location.  
- Two viable options: **MySQL GIS** (simpler) or **Meilisearch/Typesense** (better UX).  
- City autocomplete with typo tolerance and nearby expert search with distance sorting.  
- Search across Goldexperten profiles, articles, and all other content types.  

### 5. Articles & Content Management
- Provide an editorial workflow for articles via Pimcore.  
- Features for the editorial team:  
  - Add new articles easily with components (text, images, graphs, etc.).  
  - Toggle article **live/offline**.  
  - Schedule **publish dates** for automatic publishing.  
- Frontend should offer a **clean and simple reader experience**.  

---

## Detailed Implementation Guide

### 1. Precious Metal Data Integration - Implementation Details

**What to do:**
- Set up a scheduled job/cron in Pimcore to fetch metal prices from metals-api.com
- Create a DataObject class for storing metal prices with timestamp, metal type, price, and currency
- Implement REST API endpoints to serve cached price data to frontend
- Add error handling and fallback mechanisms

**How to achieve this fastest:**
1. Create a Symfony command in Pimcore (`src/Command/FetchMetalPricesCommand.php`)
2. Use Guzzle HTTP client for API calls to metals-api.com
3. Store prices in Pimcore DataObjects with proper validation
4. Set up a cron job to run every few hours (respect the 200 calls/month limit)
5. Create REST endpoints using Pimcore's REST API or custom controllers

**What to look out for:**
- API rate limiting (200 calls/month = ~6-7 calls/day maximum)
- Handle API failures gracefully with cached fallbacks
- Store historical data for trend analysis
- Validate API responses before saving

**Mistakes to avoid:**
- Don't exceed API rate limits
- Don't make real-time API calls from frontend
- Don't forget to handle timezone differences
- Don't store sensitive API keys in code (use environment variables)

### 2. Data Objects in Pimcore - Implementation Details

**What to do:**
- Design and implement DataObject classes for all content types
- Set up proper field definitions, validation rules, and relationships
- Configure permissions and workflows

**How to achieve this fastest:**
1. Start with the most critical objects: Expert Profiles, Articles, Forms
2. Use Pimcore's class definition GUI for rapid prototyping
3. Export class definitions to version control once finalized
4. Set up proper inheritance hierarchy to avoid duplication

**What to look out for:**
- Plan relationships between objects carefully (avoid circular dependencies)
- Consider multilingual requirements from the start
- Design flexible field structures that can accommodate future changes
- Set up proper indexing for search functionality

**Mistakes to avoid:**
- Don't create too many small classes (group related fields)
- Don't forget to set up proper validation rules
- Don't hardcode field names in frontend code
- Don't ignore Pimcore's built-in SEO fields

#### 2.1. Expert Profiles - Implementation Details

**What to do:**
- Create ExpertProfile DataObject with fields: name, bio, location, contact info, specialties, images, status
- Implement workflow states (draft, review, live, inactive)
- Set up REST API endpoints for profile data
- Configure Next.js ISR for profile pages

**How to achieve this fastest:**
1. Create the DataObject class with all required fields
2. Add workflow states and permissions
3. Build REST API endpoint that returns profile data
4. Set up Next.js dynamic routes with ISR revalidation
5. Create profile page template that consumes API data

**What to look out for:**
- Image handling and optimization
- SEO metadata for each profile
- Proper URL structure for SEO
- Validation of required fields before going live

**Mistakes to avoid:**
- Don't forget to handle image uploads and resizing
- Don't create profiles without proper SEO data
- Don't hardcode URLs in the frontend
- Don't skip validation workflows

### 3. Form Handling - Implementation Details

**What to do:**
- Create form submission DataObjects to store customer requests
- Build API endpoints for form submission
- Implement email notification system
- Set up admin interface for reviewing submissions

**How to achieve this fastest:**
1. Create FormSubmission DataObject with all necessary fields
2. Build REST API endpoint for form submission with validation
3. Set up email templates and notification system using Symfony Mailer
4. Create admin views in Pimcore for reviewing submissions
5. Implement approval/rejection workflow with automated emails

**What to look out for:**
- GDPR compliance for form data
- Spam protection (rate limiting, CAPTCHA)
- Email deliverability
- Proper validation and sanitization

**Mistakes to avoid:**
- Don't store sensitive data without encryption
- Don't forget CSRF protection
- Don't send emails without proper templates
- Don't skip form validation on both client and server side

### 4. Search Functionality - Implementation Details

**What to do:**
- Implement geo-based search for finding nearby Goldexperten by city/location
- Choose between MySQL GIS (simpler) or Meilisearch/Typesense (better UX)
- Create City DataObject with coordinates and Expert DataObject with location data
- Implement city autocomplete and nearby expert search with distance sorting

**How to achieve this fastest:**

**Option A - MySQL GIS (Recommended for quick start):**
1. Create City DataObject with `lat`, `lon`, `location` POINT SRID 4326 fields
2. Add spatial indexes on location fields for performance
3. Use `ST_Distance_Sphere()` for nearby queries within radius
4. Implement city autocomplete with LIKE queries or FULLTEXT index
5. Create `/api/cities/suggest` and `/api/experts/near` endpoints

**Option B - Meilisearch/Typesense (Better UX):**
1. Set up Meilisearch or Typesense container in Docker
2. Create indexes for cities and experts with geo fields
3. Implement automatic sync from Pimcore events (publish/unpublish)
4. Use built-in geo-filtering and typo-tolerant search
5. Leverage faceted search for categories and filters

**What to look out for:**
- Spatial indexing on location fields (POINT SRID 4326) for performance
- Geocoding service integration for address → coordinates conversion
- City data normalization (include alternate names like Wien/Vienna)
- Input validation for lat/lon/radius parameters (set max radius ~100km)
- SEO-friendly city landing pages (/de/experten/wien/)

**Mistakes to avoid:**
- Don't skip spatial indexes (queries will be slow)
- Don't hardcode coordinates (use proper geocoding service)
- Don't forget to handle invalid coordinates or failed geocoding
- Don't expose raw search engine details in API (keep implementation flexible)
- Don't forget to cache nearby queries (60-120s) for performance

### 5. Articles & Content Management - Implementation Details

**What to do:**
- Create Article DataObject with rich content capabilities
- Implement editorial workflow with draft/review/publish states
- Set up scheduled publishing functionality
- Build content blocks/components system

**How to achieve this fastest:**
1. Design Article DataObject with flexible content fields
2. Use Pimcore's built-in workflow features for editorial process
3. Implement scheduled publishing with cron jobs
4. Create reusable content blocks (text, images, videos, etc.)
5. Set up REST API for article content
6. Build article listing and detail pages in Next.js

**What to look out for:**
- SEO optimization for articles
- Image optimization and lazy loading
- Content versioning and revision history
- Social sharing and meta tags

**Mistakes to avoid:**
- Don't create a monolithic article structure
- Don't forget to implement proper URL slugs
- Don't skip content validation before publishing
- Don't ignore mobile responsiveness for reading experience

---

## Priority Order for Fastest Implementation:

1. **Start with Precious Metal Data Integration** (1-2 days) - This provides immediate value and is relatively simple
2. **Implement Expert Profiles DataObject and API** (2-3 days) - Core functionality for the site
3. **Set up Form Handling** (1-2 days) - Essential for user interaction
4. **Build Articles & Content Management** (3-4 days) - Important for SEO
5. **Add Search Functionality** (2-3 days) - Enhancement feature

## General Tips for Speed:

- Use Pimcore's code generation features where possible
- Leverage existing Symfony bundles for common functionality
- Set up proper development environment with hot reloading
- Use Docker for consistent development environment
- Implement logging and debugging early
- Write basic tests for critical functionality
- Document API endpoints as you build them  
