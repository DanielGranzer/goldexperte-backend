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
- Integrate **Elasticsearch** for powerful, detailed search.  
- Search across Goldexperten profiles, articles, and all other content types.  

### 5. Articles & Content Management
- Provide an editorial workflow for articles via Pimcore.  
- Features for the editorial team:  
  - Add new articles easily with components (text, images, graphs, etc.).  
  - Toggle article **live/offline**.  
  - Schedule **publish dates** for automatic publishing.  
- Frontend should offer a **clean and simple reader experience**.  
