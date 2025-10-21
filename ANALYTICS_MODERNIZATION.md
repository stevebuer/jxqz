# Website Analytics Modernization

## Current State
- Previously used Webalizer for search term analysis
- Need modern replacement for visitor analytics and search insights

## Modern Analytics Options

### 🔥 Top Recommendations

#### 1. Google Analytics 4 (GA4) - Most Popular
- **Search Insights**: Organic search queries, landing pages, search console integration
- **Real-time**: Live visitor tracking, behavior flow
- **Cost**: Free (up to 10M events/month)
- **Privacy**: GDPR compliant with proper configuration
- **Setup**: Single JavaScript snippet

#### 2. Matomo (Self-hosted) - Privacy-Focused
- **Benefits**: Full data ownership, no third-party sharing
- **Search Keywords**: Detailed search term analysis, referrer tracking
- **Real-time**: Live dashboard, visitor maps
- **Privacy**: Built-in GDPR controls, cookie-free tracking option
- **Cost**: Free self-hosted, €19/month cloud

#### 3. Plausible Analytics - Lightweight & Privacy-First
- **Benefits**: Clean interface, <1KB script, doesn't slow site
- **Privacy**: No cookies, GDPR compliant by default
- **Search Data**: Top pages, referrers, search terms
- **Cost**: $9/month for 10K pageviews

### 🔍 Search-Specific Tools

#### Google Search Console - Essential & Free
- **Search Queries**: Exact terms people use to find your site
- **Click Data**: Impressions vs clicks, position tracking
- **Performance**: Page-by-page search analytics
- **Integration**: Works with GA4 for complete picture

### 📊 Self-Hosted Options (Webalizer Replacements)

#### GoAccess - Real-time Web Log Analyzer
```bash
# Install and setup
sudo apt install goaccess
goaccess /var/log/apache2/access.log -o /var/www/html/stats.html --log-format=COMBINED --real-time-html
```
- **Real-time**: Live HTML dashboard
- **Search Terms**: Extracts search queries from referrers
- **Performance**: Processes large logs quickly
- **Cost**: Free (open source)

#### AWStats - Classic Log Analyzer
- **Features**: Comprehensive visitor statistics, search keyword analysis
- **Maturity**: Well-established, well-documented
- **Cost**: Free (open source)

## 💡 Recommended Implementation Plan

### Phase 1: Essential (Free)
1. **Google Search Console** - Set up for search query insights
2. **GoAccess** - Replace Webalizer with real-time log analysis

### Phase 2: Enhanced Analytics
1. **Matomo Self-hosted** - Full-featured privacy-respecting analytics
2. **Google Analytics 4** - Industry-standard analytics (if privacy allows)

### Phase 3: Professional (Optional)
1. **SEMrush/Ahrefs** - Advanced SEO and competitor analysis ($99+/month)

## Implementation Tasks
- [ ] Set up Google Search Console verification
- [ ] Install and configure GoAccess for real-time log analysis
- [ ] Evaluate Matomo self-hosted installation
- [ ] Configure Apache logs for optimal analytics data
- [ ] Set up analytics dashboard integration
- [ ] Privacy compliance review (GDPR considerations)

## Technical Requirements
- Apache log access (already available)
- Web server space for analytics dashboard
- SSL certificate for secure analytics (already have)
- Potential database setup for Matomo
- JavaScript inclusion for client-side analytics

## Benefits Over Webalizer
- Real-time data instead of periodic reports
- Search query insights (not just referrer domains)
- Mobile and device analytics
- User behavior tracking
- Better search engine optimization insights
- Modern, responsive dashboards
- Privacy compliance options

---
*Created: 2025-10-20*  
*Context: Infrastructure modernization session*  
*Priority: Medium (after storage/Docker crisis resolution)*