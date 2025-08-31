# Goldexperte Pimcore Data Object Setup & Usage Guide

## 📋 Overview

This guide explains how to set up and use the Goldexperte data object in Pimcore for managing goldexperten profile pages. The data object is designed to match your TypeScript interface and provide seamless integration with your Next.js frontend via ISR (Incremental Static Regeneration).

## 🚀 Quick Start

### 1. Import the Data Object Class

1. **Copy the class definition:**
   - Copy `definition_Goldexperte_simple.json` to your Pimcore installation
   - Or use the full definition for complete field structure

2. **Import via Pimcore Admin:**
   - Go to **Settings** → **Data Objects** → **Classes**
   - Click **Add** → **Import Class Definition**
   - Upload the JSON file
   - **Important:** Enable "Generate Type Declarations" for better IDE support

3. **Run database migration:**
   ```bash
   php bin/console pimcore:deployment:classes-rebuild
   ```

### 2. Set Up Folder Structure

Create the following folder structure in **Objects**:
```
/
├── goldexperten/
│   ├── regensburg/
│   ├── berlin/
│   ├── münchen/
│   └── ...other cities/
```

### 3. Migration Script

Run the migration command to import existing data:
```bash
php bin/console app:migrate-goldexperten
```

## 🏗️ Data Object Field Structure

### Core Fields

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `businessName` | Input | ✅ | Official business name |
| `title` | Input | ✅ | Display title (usually "Goldexperte") |
| `slug` | Input | ⚠️ | URL slug (auto-generated if empty) |
| `description` | Textarea | ✅ | Business description |
| `isLive` | Checkbox | 🔴 | **CRITICAL: Makes profile public & triggers ISR** |

### Contact Information

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `address` | Textarea | ✅ | Full business address |
| `city` | Input | ✅ | City name (indexed for search) |
| `postalCode` | Input | ✅ | Postal code |
| `telephone` | Input | ✅ | Phone number |
| `email` | Email | ✅ | Contact email |
| `website` | Input | ❌ | Website URL |

### Media

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `imageUrl` | Image | ✅ | Main profile image |
| `imageAlt` | Input | ❌ | Alt text for accessibility |
| `aboutImageUrl` | Image | ✅ | About section image |
| `imageFocusPoint` | Input | ❌ | Image focus point |

### Business Details

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `open` | Checkbox | ✅ | Currently operational |
| `rating` | Numeric | ✅ | Average rating (0-5) |
| `reviewCount` | Numeric | ✅ | Total number of reviews |
| `specialties` | Multiselect | ✅ | Business specialties |
| `certified` | Checkbox | ❌ | Certification status |
| `certificationDate` | Date | ❌ | Date of certification |

### Opening Hours

| Field Name | Type | Description |
|------------|------|-------------|
| `monday` - `sunday` | Input | Daily opening hours |

### Special Features

| Field Name | Type | Description |
|------------|------|-------------|
| `hasGexDays` | Checkbox | Participates in GEX days |
| `calendarType` | Select | Calendar integration type |
| `calendarLink` | Input | Booking calendar URL |

### Social Media & Maps

| Field Name | Type | Description |
|------------|------|-------------|
| `facebookUrl` | Input | Facebook page URL |
| `instagramUrl` | Input | Instagram profile URL |
| `twitterUrl` | Input | Twitter profile URL |
| `googleMapsUrl` | Textarea | Google Maps URL |
| `mapEmbedUrl` | Textarea | Embedded map iframe |

### SEO

| Field Name | Type | Description |
|------------|------|-------------|
| `seoTitle` | Input | Meta title (auto-generated if empty) |
| `seoDescription` | Textarea | Meta description |
| `seoKeywords` | Tags | SEO keywords |

## ⚠️ CRITICAL: The `isLive` Field

The `isLive` checkbox is the most important field in the data object:

### 🔴 When `isLive = false` (Default):
- Profile is **NOT visible** in location searches
- Profile page returns **404**
- Safe for editing and preparation

### 🔴 When `isLive = true`:
- Profile **immediately becomes public**
- Triggers **ISR revalidation** automatically
- Profile appears in city searches
- Profile page becomes accessible at `/goldexperten/{city}/{slug}`

### Best Practices:
1. ✅ Complete all required fields first
2. ✅ Upload and optimize images
3. ✅ Test preview functionality
4. ✅ **Only check `isLive` when completely ready**
5. ❌ **Never check `isLive` for incomplete profiles**

## 🔄 ISR Integration

The system automatically triggers Next.js ISR when:

### Automatic Triggers:
- ✅ `isLive` changes from `false` to `true`
- ✅ Any field changes on a live profile
- ✅ Profile is saved with `isLive = true`

### Revalidated Paths:
- `/goldexperten/{city}/{slug}` - Individual profile page
- `/goldexperten/{city}` - City overview page
- `/` - Homepage (for featured goldexperten)
- `/standortsuche` - Location search results

### Manual ISR Trigger:
```bash
curl -X POST https://your-pimcore-domain.com/api/webhooks/trigger-isr/{goldexperteId}
```

## 📡 API Endpoints

### Frontend Integration Endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/goldexperten` | GET | List all live goldexperten |
| `/api/v1/goldexperten/city/{city}` | GET | Get goldexperten by city |
| `/api/v1/goldexperten/{slug}` | GET | Get single goldexperte |
| `/api/v1/goldexperten/featured` | GET | Get featured goldexperte |
| `/api/v1/goldexperten/search?q={query}` | GET | Search goldexperten |

### Example API Response:
```json
{
  "id": 1,
  "title": "Goldexperte",
  "businessName": "Juwelier Mühlbacher",
  "address": "Ludwigstraße 1, 93047 Regensburg",
  "telephone": "+49 941 5027970",
  "email": "info@muehlbacher.de",
  "website": "https://www.muehlbacher.de/",
  "imageUrl": "/assets/goldexperten/profile-images/muehlbacher.jpg",
  "city": "Regensburg",
  "slug": "juwelier-muehlbacher-regensburg",
  "openingHours": {
    "monday": "10:00 - 13:00 & 14:00 - 18:00",
    "tuesday": "10:00 - 13:00 & 14:00 - 18:00",
    // ...
  },
  "specialties": ["Goldankauf", "Schmuckbewertung", "Uhrenankauf"],
  "rating": 4.5,
  "reviewCount": 127,
  "certified": true,
  "isLive": true
}
```

## 📝 Admin Workflow

### Creating a New Goldexperte Profile:

1. **Navigate to Objects:**
   - Go to **Objects** → **goldexperten**
   - Choose appropriate city folder

2. **Create New Object:**
   - Right-click → **Add** → **Goldexperte**
   - Name the object with a descriptive key

3. **Fill Required Fields:**
   - ✅ Business Name
   - ✅ Title (usually "Goldexperte")
   - ✅ Description
   - ✅ Contact Information
   - ✅ Images
   - ✅ Rating & Review Count
   - ✅ Specialties

4. **Save as Draft:**
   - **Save** with `isLive = false`
   - Test and preview

5. **Go Live:**
   - When ready, check `isLive = true`
   - **Save** - this triggers ISR automatically

### Editing Existing Profiles:

1. **For Live Profiles:**
   - Changes auto-trigger ISR
   - Be careful with major changes during business hours

2. **For Draft Profiles:**
   - Safe to edit extensively
   - No public impact until `isLive = true`

## 🔍 SEO & Performance

### Auto-Generated SEO:
If SEO fields are empty, the system auto-generates:
- **Title:** `{businessName} {city} - Goldankauf & Edelmetalle`
- **Description:** Based on business description and location
- **Keywords:** Derived from specialties and location

### Performance Considerations:
- ✅ Images are automatically optimized via Pimcore
- ✅ ISR ensures fast page loads
- ✅ API responses are cached
- ✅ Database queries are indexed (city, slug, isLive)

## 🚨 Important Notes

### Security:
- Only authorized users should have access to `isLive` checkbox
- Consider role-based permissions for different admin users
- Monitor ISR triggers in production

### Data Integrity:
- Slug must be unique across all goldexperten
- City names should be consistent (lowercase)
- Email addresses are validated
- Rating must be between 0-5

### Monitoring:
- Check ISR trigger logs: `/var/logs/pimcore.log`
- Monitor API performance
- Track profile creation/publication metrics

## 🛠️ Development & Testing

### Local Development:
```bash
# Start Pimcore
docker-compose up -d

# Import class definition
# Access admin at http://localhost/admin

# Test API endpoints
curl http://localhost/api/v1/goldexperten?city=regensburg
```

### Testing ISR:
1. Create test goldexperte with `isLive = false`
2. Check that profile returns 404
3. Set `isLive = true` and save
4. Verify profile becomes accessible
5. Check that city page shows new profile

---

## 📞 Support

For issues or questions regarding the Goldexperte data object:

1. Check Pimcore logs: `/var/logs/`
2. Verify database schema matches class definition
3. Test API endpoints manually
4. Monitor ISR webhook responses

The data object is designed to provide a seamless content management experience while ensuring that your goldexperte profiles are always up-to-date on the frontend through automatic ISR integration.
