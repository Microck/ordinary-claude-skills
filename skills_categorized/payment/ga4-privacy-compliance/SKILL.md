---
name: ga4-privacy-compliance
description: Expert guidance for GA4 privacy and compliance including GDPR, CCPA, Consent Mode v2, data deletion, and privacy settings. Use when implementing Consent Mode, ensuring GDPR compliance, handling data deletion requests, configuring consent banners, or implementing privacy-first tracking. Covers consent parameters (ad_user_data, ad_personalization), data retention, IP anonymization, and compliance workflows.
---

# GA4 Privacy and Compliance

## Overview

GA4 provides privacy-focused features for GDPR, CCPA, and global privacy regulations including Consent Mode, data controls, and compliance workflows.

## When to Use This Skill

Invoke this skill when:

- Implementing Consent Mode v2 for GDPR compliance
- Setting up consent banners and consent management platforms (CMPs)
- Configuring privacy settings for EU/EEA users
- Handling GDPR/CCPA data deletion requests
- Implementing privacy-first tracking strategies
- Setting consent parameters (ad_storage, analytics_storage)
- Configuring data retention policies
- Managing user opt-outs and privacy requests
- Working with consent management platforms (OneTrust, Cookiebot)
- Implementing server-side consent tracking
- Debugging consent mode implementation
- Ensuring regulatory compliance for analytics

## Core Capabilities

### Consent Mode v2

**What is Consent Mode:**
Google's API for communicating user consent status to GA4, Google Ads, and other Google tags.

**Consent Parameters (v2):**

1. **ad_storage**
   - Purpose: Advertising cookies (remarketing, conversion tracking)
   - Values: "granted" | "denied"

2. **analytics_storage**
   - Purpose: Analytics cookies (GA4 tracking)
   - Values: "granted" | "denied"

3. **ad_user_data** (NEW in v2)
   - Purpose: User data sharing for advertising
   - Values: "granted" | "denied"

4. **ad_personalization** (NEW in v2)
   - Purpose: Personalized advertising
   - Values: "granted" | "denied"

**Additional Parameters:**

5. **personalization_storage**
   - Purpose: Website personalization
   - Values: "granted" | "denied"

6. **functionality_storage**
   - Purpose: Essential site functionality
   - Values: "granted" | "denied"

7. **security_storage**
   - Purpose: Security features (fraud prevention)
   - Values: "granted" | "denied"

### Implementing Consent Mode

**Basic Implementation (gtag.js):**

**Step 1: Set Default Consent State (BEFORE gtag.js)**

```html
<script>
  // Set default consent to denied
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}

  gtag('consent', 'default', {
    'ad_storage': 'denied',
    'ad_user_data': 'denied',
    'ad_personalization': 'denied',
    'analytics_storage': 'denied'
  });

  // Configure GA4
  gtag('config', 'G-XXXXXXXXXX');
</script>

<!-- Load gtag.js -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
```

**Step 2: Update Consent After User Choice**

```javascript
// When user accepts all cookies
gtag('consent', 'update', {
  'ad_storage': 'granted',
  'ad_user_data': 'granted',
  'ad_personalization': 'granted',
  'analytics_storage': 'granted'
});

// When user accepts only analytics
gtag('consent', 'update', {
  'ad_storage': 'denied',
  'ad_user_data': 'denied',
  'ad_personalization': 'denied',
  'analytics_storage': 'granted'
});

// When user denies all
gtag('consent', 'update', {
  'ad_storage': 'denied',
  'ad_user_data': 'denied',
  'ad_personalization': 'denied',
  'analytics_storage': 'denied'
});
```

**GTM Implementation:**

**Method 1: Using Consent Mode Template**

1. **Install CMP Template** (OneTrust, Cookiebot, etc.)
2. Configure default consent in template
3. Template auto-updates consent on user choice

**Method 2: Manual GTM Setup**

**Create Consent Initialization Tag:**
1. Tag Type: Custom HTML
2. Code:
```html
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('consent', 'default', {
    'ad_storage': 'denied',
    'analytics_storage': 'denied',
    'ad_user_data': 'denied',
    'ad_personalization': 'denied'
  });
</script>
```
3. Trigger: Consent Initialization - All Pages
4. Tag firing priority: 999 (fires first)

**Create Consent Update Tag (on user acceptance):**
1. Tag Type: Custom HTML
2. Code: `gtag('consent', 'update', ...)`
3. Trigger: Custom event from CMP (e.g., `consent_granted`)

### Regional Settings

**EU-Specific Consent:**

```javascript
gtag('consent', 'default', {
  'ad_storage': 'denied',
  'analytics_storage': 'denied'
}, {
  'region': ['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'GB']
});

gtag('consent', 'default', {
  'ad_storage': 'granted',
  'analytics_storage': 'granted'
}, {
  'region': ['US-CA']  // California - CCPA
});
```

### Consent Mode Behavior

**When analytics_storage = "denied":**
- GA4 uses cookieless pings
- No client_id stored in cookies
- Modeling used to fill gaps
- Limited user tracking
- Session duration not tracked

**When analytics_storage = "granted":**
- Full GA4 tracking enabled
- Cookies stored
- client_id persists
- Complete user journey tracking

**Conversion Modeling:**
When consent denied, GA4 uses:
- Machine learning to estimate conversions
- Aggregated, anonymized data
- Behavioral modeling
- "Modeled" label in reports

### Data Retention Settings

**Path:** Admin → Data Settings → Data Retention

**Options:**
- **2 months** (default)
- **14 months**

**Applies To:**
- User-level data in Explorations
- Event-level data in Explorations
- Does NOT affect standard reports

**Reset on New Activity:**
- ON: Timer resets when user returns (rolling window)
- OFF: Data deleted based on original collection date

**GDPR Compliance:**
- Shorter retention = more privacy-focused
- Document retention policy in privacy policy
- Consider BigQuery export for longer storage

### Data Deletion Requests

**User Right to Deletion (GDPR Article 17):**

**Deleting User Data:**

1. **Admin → Data Settings → Data Deletion Requests**
2. **Create Deletion Request**
3. Choose deletion parameter:
   - **User ID:** Delete by user_id
   - **Client ID:** Delete by client_id (user_pseudo_id)
   - **App Instance ID:** Delete by app instance
4. Enter identifier value
5. Choose date range or "All time"
6. Submit request

**Processing:**
- Takes up to 72 hours
- Deletes ALL events for that identifier
- Cannot be undone
- Confirmation email sent when complete

**Best Practice:**
- Maintain deletion request log
- Respond to requests within 30 days (GDPR requirement)
- Document process in privacy policy

### IP Anonymization

**GA4 Default Behavior:**
- GA4 does NOT log or store IP addresses
- IP used only for geo-location derivation
- No additional anonymization needed

**Unlike Universal Analytics:**
- No `anonymize_ip` parameter needed
- Privacy-first by design
- IP address never in reports or exports

### Google Signals

**What It Enables:**
- Demographics reporting (age, gender)
- Interests reporting
- Cross-device tracking (without User ID)
- Remarketing audiences

**Privacy Implications:**
- Requires user consent for personalized ads
- Subject to data thresholds
- User opt-out via Ads Settings

**Enabling:**
Admin → Data Settings → Data Collection → Google Signals

**Recommendation:**
- Enable only with proper consent
- Respect user opt-outs
- Document in privacy policy

### Data Thresholds

**What Are Thresholds:**
GA4 applies thresholds to reports when:
- Small user counts could reveal individual identity
- Google Signals enabled
- User demographics requested

**When Applied:**
- Small audience sizes
- Rare combinations of dimensions
- Reports show "(thresholded)" or data withheld

**Managing Thresholds:**
- Disable Google Signals (if not needed)
- Use broader date ranges
- Aggregate dimensions
- Export to BigQuery for unthresholded data

### Consent Management Platforms (CMPs)

**Popular CMPs:**
- OneTrust
- Cookiebot
- Termly
- Osano
- TrustArc

**GTM CMP Templates:**
Most CMPs provide GTM templates:
1. **Community Template Gallery** → Search CMP name
2. Install template
3. Configure CMP settings
4. Auto-updates consent to GA4

**Example: Cookiebot Integration**
1. Install Cookiebot tag on site
2. Install Cookiebot template in GTM
3. Template auto-sets default consent
4. Updates consent based on user choice
5. No manual gtag('consent') needed

### GDPR Compliance Checklist

- [ ] Privacy policy updated with GA4 usage
- [ ] Cookie consent banner implemented
- [ ] Consent Mode v2 configured (all 4 parameters)
- [ ] Default consent set to "denied" for EU users
- [ ] Consent updates on user acceptance
- [ ] Data retention configured (2 or 14 months)
- [ ] Data deletion process documented
- [ ] User opt-out mechanism available
- [ ] Google Signals consent obtained (if enabled)
- [ ] Cross-border data transfer disclosures
- [ ] DPA (Data Processing Agreement) with Google signed
- [ ] Regular privacy audit schedule

### CCPA Compliance

**Requirements:**
- Allow users to opt out of "sale" of personal information
- Provide "Do Not Sell My Personal Information" link
- Honor Global Privacy Control (GPC)

**Implementation:**

```javascript
// Detect GPC signal
if (navigator.globalPrivacyControl) {
  gtag('consent', 'update', {
    'ad_storage': 'denied',
    'ad_user_data': 'denied',
    'ad_personalization': 'denied',
    'analytics_storage': 'granted'  // Analytics OK, ads denied
  });
}
```

**GTM Variable for GPC:**
1. Variable Type: JavaScript Variable
2. Global Variable Name: `navigator.globalPrivacyControl`
3. Use in Consent Mode logic

### Testing Consent Mode

**Verification Steps:**

1. **DebugView Test:**
   - Enable DebugView
   - Before consent: Check `analytics_storage = denied`
   - After consent: Check `analytics_storage = granted`

2. **Check Event Parameters:**
   - Events should include consent status
   - Look for `gcs` parameter (Google Consent State)

3. **Cookie Inspection:**
   - Before consent: No `_ga` cookie
   - After consent: `_ga` cookie set

4. **GTM Preview:**
   - Verify Consent Initialization tag fires first
   - Verify GA4 tag respects consent
   - Verify consent update tags fire on user action

**Chrome DevTools:**
```javascript
// Check current consent state
dataLayer.filter(item => item[0] === 'consent')
```

### Server-Side Consent

**Measurement Protocol with Consent:**

```json
{
  "client_id": "client_123",
  "consent": {
    "ad_storage": "denied",
    "analytics_storage": "granted",
    "ad_user_data": "denied",
    "ad_personalization": "denied"
  },
  "events": [...]
}
```

**Best Practice:**
- Pass consent status from frontend to backend
- Include in all Measurement Protocol requests
- Store user consent preferences in database

## Integration with Other Skills

- **ga4-setup** - Privacy settings during property setup
- **ga4-gtag-implementation** - Implementing Consent Mode with gtag.js
- **ga4-gtm-integration** - GTM Consent Mode setup
- **ga4-data-management** - Data retention and deletion
- **ga4-user-tracking** - User ID and privacy considerations
- **ga4-measurement-protocol** - Server-side consent parameters

## References

- **references/consent-mode-complete.md** - Complete Consent Mode v2 implementation guide
- **references/gdpr-compliance.md** - GDPR compliance requirements and workflows
- **references/ccpa-compliance.md** - CCPA compliance guide
- **references/cmp-integrations.md** - Integrating popular consent management platforms

## Quick Reference

**Consent Parameters (v2):**
- `ad_storage`: Advertising cookies
- `analytics_storage`: Analytics cookies
- `ad_user_data`: User data sharing (NEW)
- `ad_personalization`: Personalized ads (NEW)

**Set Default (Before Consent):**
```javascript
gtag('consent', 'default', {
  'ad_storage': 'denied',
  'analytics_storage': 'denied',
  'ad_user_data': 'denied',
  'ad_personalization': 'denied'
});
```

**Update After User Accepts:**
```javascript
gtag('consent', 'update', {
  'ad_storage': 'granted',
  'analytics_storage': 'granted',
  'ad_user_data': 'granted',
  'ad_personalization': 'granted'
});
```

**Data Deletion:**
Admin → Data Deletion Requests → Create
