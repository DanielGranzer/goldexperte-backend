# Metals API Integration Guide

## Overview

This integration provides efficient metal price management for the GoldExperte platform using metals-api.com with intelligent rate limiting. The system optimizes API usage by caching data in Pimcore and serving unlimited frontend requests.

## Architecture

```
metals-api.com (200 calls/month)
       ↓
MetalsApiService (Smart Rate Limiting)
       ↓
Pimcore Data Objects (Cache)
       ↓
API Controller (Unlimited calls)
       ↓ 
Frontend MetalsService
```

## Components

### 1. Backend Components

#### MetalPrice Data Object (`src/DataObject/MetalPrice.php`)
- Stores precious metal prices in Pimcore
- Supports gold, silver, platinum, palladium
- Tracks pricing history and API usage
- Automatic activation management

#### MetalsApiService (`src/Service/MetalsApiService.php`)
- Integrates with metals-api.com
- Smart rate limiting (200 calls/month)
- Sunday: 1 call max, Weekdays: 8 calls max
- Historical data fetching

#### MetalPricesController (`src/Controller/Api/MetalPricesController.php`)
- REST API for frontend consumption
- Unlimited calls (served from cache)
- Health monitoring and admin endpoints

#### UpdateMetalPricesCommand (`src/Command/UpdateMetalPricesCommand.php`)
- Console command for automated updates
- Can be scheduled via cron jobs
- Dry-run and force update options

### 2. Frontend Components

#### MetalsService (`src/services/metalsService.ts`)
- TypeScript service for metal price data
- Client-side caching (5 minutes)
- Duplicate request prevention
- Formatted price display helpers

#### Types (`src/types/precious-metals.ts`)
- Complete TypeScript definitions
- API response interfaces
- Metal and time range types

## Setup Instructions

### 1. Backend Setup

1. **Install the Pimcore data object:**
```bash
# Copy class definition to Pimcore
cp var/classes/definition_MetalPrice_simple.json /path/to/pimcore/var/classes/

# Or create via admin panel using the provided JSON structure
```

2. **Configure the service:**
```php
// config/services.yaml
services:
    App\Service\MetalsApiService:
        arguments:
            $apiKey: '%env(METALS_API_KEY)%'
```

3. **Set environment variables:**
```env
# .env
METALS_API_KEY=your-metals-api-key-here
ADMIN_API_KEY=your-admin-secret-key
```

4. **Create MetalPrices folder in Pimcore:**
- Go to Pimcore Admin → Objects
- Create folder: `/MetalPrices`
- This will store all metal price objects

### 2. Frontend Setup

1. **Install the new service:**
```bash
# The service is already created in src/services/metalsService.ts
```

2. **Configure API URL:**
```env
# .env.local
NEXT_PUBLIC_PIMCORE_API_URL=http://your-pimcore-domain.com/api
```

3. **Update your components:**
```typescript
// Replace old preciousMetalsService imports
import { metalsService } from '@/services/metalsService';

// Usage remains similar but now uses Pimcore cache
const prices = await metalsService.getCurrentPrices('EUR');
```

### 3. Automation Setup

#### Cron Job Configuration
```bash
# Edit crontab
crontab -e

# Add these lines for optimal API usage:

# Weekdays: Every 3 hours (8 calls max per day)
0 */3 * * 1-6 /path/to/php /path/to/pimcore/bin/console app:update-metal-prices

# Sunday: Once in the morning (1 call max)
0 9 * * 0 /path/to/php /path/to/pimcore/bin/console app:update-metal-prices

# Optional: Health check every hour
0 * * * * /path/to/php /path/to/pimcore/bin/console app:update-metal-prices --dry-run
```

#### Alternative: Systemd Timer
```ini
# /etc/systemd/system/metal-prices-update.timer
[Unit]
Description=Update metal prices
Requires=metal-prices-update.service

[Timer]
OnCalendar=*-*-* 06,09,12,15,18,21:00:00
Persistent=true

[Install]
WantedBy=timers.target

# /etc/systemd/system/metal-prices-update.service
[Unit]
Description=Update metal prices from metals-api.com

[Service]
Type=oneshot
User=www-data
WorkingDirectory=/path/to/pimcore
ExecStart=/path/to/php bin/console app:update-metal-prices
```

## API Endpoints

### Public Endpoints (Unlimited)

#### Get Current Prices
```
GET /api/metal-prices/current?currency=EUR
```

Response:
```json
{
  "success": true,
  "currency": "EUR",
  "prices": {
    "gold": {
      "current": 1950.50,
      "change": 15.30,
      "changePercent": 0.79,
      "currency": "EUR",
      "timestamp": 1640995200
    },
    "silver": { ... },
    "platinum": { ... },
    "palladium": { ... }
  },
  "from_cache": true
}
```

#### Get Historical Prices
```
GET /api/metal-prices/historical/gold?range=1M&currency=EUR
```

#### Health Check
```
GET /api/metal-prices/health
```

### Admin Endpoints (Require API Key)

#### Force Update
```
POST /api/metal-prices/update
Headers: X-API-Key: your-admin-key
Body: currency=EUR&force=false
```

#### API Usage Statistics
```
GET /api/metal-prices/api-usage
```

## Rate Limiting Strategy

### Monthly Budget: 200 API Calls

| Day | Max Calls | Strategy |
|-----|-----------|----------|
| Sunday | 1 | Single morning update |
| Monday-Saturday | 8 | Every 3 hours |

### Smart Scheduling

The system automatically adjusts call frequency based on:
- Remaining monthly budget
- Days left in month
- Current usage patterns

Example: If you've used 150 calls by day 20, the system will reduce frequency to ensure you don't exceed 200 calls.

## Frontend Usage

### Basic Usage
```typescript
import { metalsService } from '@/services/metalsService';

// Get all current prices
const prices = await metalsService.getCurrentPrices('EUR');

// Get specific metal price
const goldPrice = await metalsService.getCurrentPrice('gold', 'EUR');

// Get historical data
const historical = await metalsService.getHistoricalPrices('gold', '1M', 'EUR');

// Format prices for display
const formatted = metalsService.formatPrice(goldPrice?.current, 'EUR');
const changeClass = metalsService.getChangeColorClass(goldPrice?.change);
```

### React Component Example
```tsx
import React, { useEffect, useState } from 'react';
import { metalsService } from '@/services/metalsService';
import { MetalPrice } from '@/types/precious-metals';

export function MetalPriceDisplay() {
  const [prices, setPrices] = useState<Record<string, MetalPrice | null>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPrices = async () => {
      try {
        const data = await metalsService.getCurrentPrices('EUR');
        setPrices(data);
      } catch (error) {
        console.error('Failed to fetch prices:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchPrices();
    
    // Refresh every 10 minutes
    const interval = setInterval(fetchPrices, 10 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  if (loading) return <div>Loading prices...</div>;

  return (
    <div className="metal-prices">
      {Object.entries(prices).map(([metal, price]) => (
        <div key={metal} className="price-card">
          <h3>{metalsService.getMetalDisplayName(metal as any)}</h3>
          <div className="price">
            {metalsService.formatPrice(price?.current, 'EUR')}
          </div>
          <div className={metalsService.getChangeColorClass(price?.change)}>
            {metalsService.formatChange(price?.changePercent, true)}
          </div>
        </div>
      ))}
    </div>
  );
}
```

## Monitoring and Maintenance

### Health Monitoring
```bash
# Check system health
curl http://your-domain.com/api/metal-prices/health

# Check API usage
curl http://your-domain.com/api/metal-prices/api-usage
```

### Manual Updates
```bash
# Test run (no API calls)
php bin/console app:update-metal-prices --dry-run

# Normal update (respects limits)
php bin/console app:update-metal-prices

# Force update (ignores limits - use sparingly!)
php bin/console app:update-metal-prices --force

# Update with historical data
php bin/console app:update-metal-prices --historical=gold
```

### Troubleshooting

#### Common Issues

1. **API Limit Exceeded**
   - Check usage: `php bin/console app:update-metal-prices --dry-run`
   - Wait for next period or use cached data
   - Adjust cron frequency if needed

2. **Stale Data**
   - Force update: `php bin/console app:update-metal-prices --force`
   - Check API health: `curl /api/metal-prices/health`

3. **Frontend Not Updating**
   - Clear browser cache
   - Check API URL configuration
   - Verify Pimcore API accessibility

#### Logs
- Pimcore logs: `var/log/dev.log` or `var/log/prod.log`
- API service logs include rate limiting information
- Console command provides detailed output

## Migration from Old Service

If you're replacing an existing metals service:

1. **Backup existing data**
2. **Update imports:**
   ```typescript
   // Old
   import { preciousMetalsService } from '@/services/preciousMetalsService';
   
   // New  
   import { metalsService } from '@/services/metalsService';
   ```

3. **Update method calls:**
   ```typescript
   // Old method names might be different
   // Check your existing implementation and map accordingly
   
   // The new service provides these main methods:
   // - getCurrentPrices()
   // - getCurrentPrice() 
   // - getHistoricalPrices()
   // - formatPrice()
   // - formatChange()
   ```

4. **Test thoroughly** before removing old service

## Performance Optimization

### Caching Strategy
- **Pimcore**: Permanent cache for API data
- **Frontend**: 5-minute client-side cache  
- **CDN**: Consider caching API responses

### Database Optimization
- Index on `metal`, `currency`, `isActive` fields
- Regular cleanup of old historical data
- Consider partitioning by month for large datasets

### API Optimization
- Batch multiple metal requests
- Use smart caching to minimize API calls
- Monitor usage patterns and adjust schedules

## Security Considerations

1. **API Key Protection**
   - Store in environment variables
   - Rotate keys regularly
   - Use different keys for dev/prod

2. **Admin Endpoints**
   - Protect with authentication
   - Rate limit admin operations
   - Log all force updates

3. **Data Validation**
   - Validate price ranges
   - Check data freshness
   - Sanitize user inputs

## Support and Maintenance

### Regular Tasks
- Monitor API usage monthly
- Review and optimize cron schedules
- Update historical data periodically
- Check for metals-api.com API changes

### Upgrades
- metals-api.com plan changes
- Pimcore version updates
- PHP/TypeScript dependency updates

This integration provides a robust, efficient system for managing precious metal prices while respecting API limits and providing excellent frontend performance.
