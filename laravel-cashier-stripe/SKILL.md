---
name: laravel-cashier-stripe
description: Laravel Cashier (Stripe) - Subscription billing and payment processing
---

# Laravel Cashier (Stripe) Skill

Comprehensive assistance with Laravel Cashier (Stripe) development for subscription billing, payment processing, and Stripe integration in Laravel applications.

## When to Use This Skill

This skill should be triggered when:
- Implementing subscription billing in Laravel applications
- Setting up recurring payments with Stripe
- Managing customer subscriptions, trials, and plan changes
- Processing one-time charges or invoices
- Handling Stripe webhooks and events
- Implementing checkout flows with Stripe Checkout
- Managing customer payment methods and cards
- Working with Stripe invoices and billing portals
- Setting up trial periods and proration logic
- Debugging Stripe integration issues in Laravel

## Quick Reference

### Installation and Setup

```bash
# Install Cashier
composer require laravel/cashier

# Publish migrations and migrate
php artisan vendor:publish --tag="cashier-migrations"
php artisan migrate

# Publish config (optional)
php artisan vendor:publish --tag="cashier-config"
```

### Configure Billable Model

```php
use Laravel\Cashier\Billable;

class User extends Authenticatable
{
    use Billable;
}
```

### Creating a Subscription

```php
// Basic subscription with trial and checkout
$user->newSubscription('default', 'price_monthly')
    ->trialDays(5)
    ->allowPromotionCodes()
    ->checkout([
        'success_url' => route('checkout.success'),
        'cancel_url' => route('checkout.cancel'),
    ]);
```

### Checking Subscription Status

```php
// Check if user has active subscription
if ($user->subscribed('default')) {
    // User is subscribed to "default" plan
}

// Check specific product subscription
if ($user->subscribedToProduct('prod_premium', 'default')) {
    // User is subscribed to premium product
}

// Check trial status
if ($user->subscription('default')->onTrial()) {
    // User is still in trial period
}
```

### Managing Payment Methods

```php
// Store payment method (in view with Stripe.js)
$intent = $user->createSetupIntent();

// Retrieve payment methods
$paymentMethods = $user->paymentMethods();
$defaultMethod = $user->defaultPaymentMethod();

// Add and update payment methods
$user->addPaymentMethod($paymentMethodId);
$user->updateDefaultPaymentMethod($paymentMethodId);
```

### Swapping Subscription Plans

```php
// Swap to different price/plan
$user->subscription('default')->swap('price_yearly');

// Swap and skip trial
$user->subscription('default')->skipTrial()->swap('price_yearly');
```

### Single Charges and Invoices

```php
// One-time charge
$user->charge(1000, $paymentMethodId, [
    'description' => 'One-time charge',
]);

// Create invoice for service
$user->invoiceFor('Premium Support', 5000, [
    'description' => '3 months of premium support',
]);

// Refund a charge
$user->refund($chargeId);
```

### Canceling Subscriptions

```php
// Cancel immediately
$user->subscription('default')->cancel();

// Cancel at end of billing period
$user->subscription('default')->cancelAtEndOfBillingPeriod();

// Resume canceled subscription
if ($user->subscription('default')->onGracePeriod()) {
    $user->subscription('default')->resume();
}
```

### Working with Invoices

```php
// Get all invoices
$invoices = $user->invoices();

// Get upcoming invoice
$upcomingInvoice = $user->upcomingInvoice('default');

// Download invoice PDF
return $user->invoices()->first()->download();
```

### Billing Portal Integration

```php
// Redirect to Stripe billing portal
Route::get('/billing', function (Request $request) {
    return $request->user()
        ->redirectToBillingPortal(route('dashboard'));
})->middleware(['auth']);
```

### Customer Management

```php
// Create/get Stripe customer
$stripeCustomer = $user->createOrGetStripeCustomer();

// Update customer details
$user->updateStripeCustomer([
    'name' => 'Updated Name',
    'email' => 'updated@example.com',
]);

// Manage tax IDs
$taxId = $user->createTaxId('eu_vat', 'BE0123456789');
$user->deleteTaxId('txi_belgium');
```

## Key Concepts

### Billable Model
The `Billable` trait adds subscription and payment functionality to your Eloquent models (typically `User`). It provides methods for creating subscriptions, processing charges, managing payment methods, and accessing invoices.

### Subscriptions
Cashier manages recurring billing through subscriptions. Each subscription has:
- **Name**: Identifier like "default" or "premium"
- **Price ID**: Stripe price identifier (e.g., "price_monthly")
- **Status**: Active, trialing, canceled, incomplete, etc.
- **Trial period**: Optional trial days before charging
- **Metered billing**: Support for usage-based pricing

### Payment Methods
Stripe payment methods represent stored payment credentials (cards, bank accounts). Cashier provides helpers to:
- Store payment methods securely via Setup Intents
- Set default payment methods for subscriptions
- Update and delete payment methods
- Handle payment method verification

### Webhooks
Stripe sends webhook events for subscription changes, payment failures, invoice updates, etc. Cashier automatically handles common webhooks, but you can extend functionality by listening to specific events.

### Checkout Sessions
Stripe Checkout provides a pre-built payment page. Cashier simplifies creating checkout sessions for subscriptions and one-time products, handling the complete payment flow with minimal code.

### Invoices
Cashier provides access to Stripe invoices for both subscriptions and one-time charges. You can retrieve, preview, and download invoices as PDFs.

## Reference Files

This skill includes comprehensive documentation in `references/`:

- **other.md** - Complete Laravel Cashier documentation covering:
  - Installation and configuration
  - Subscription management (create, swap, cancel, resume)
  - Payment method handling and Setup Intents
  - Single charges and invoicing
  - Stripe Checkout integration
  - Webhook handling and event processing
  - Customer portal integration
  - Tax ID management
  - Testing strategies

Use `view` to read the reference file when you need detailed information about specific features.

## Working with This Skill

### For Beginners

Start by:
1. Installing Cashier and running migrations
2. Adding the `Billable` trait to your `User` model
3. Setting up environment variables (STRIPE_KEY, STRIPE_SECRET)
4. Creating your first subscription with `newSubscription()`
5. Testing with Stripe test mode API keys

**Basic workflow:**
```php
// 1. Configure model
use Laravel\Cashier\Billable;
class User extends Authenticatable { use Billable; }

// 2. Create subscription
$user->newSubscription('default', 'price_monthly')->create();

// 3. Check status
if ($user->subscribed('default')) {
    // Grant access
}
```

### For Intermediate Users

Focus on:
- Implementing complete checkout flows with Stripe Checkout
- Managing payment method changes and updates
- Handling subscription plan swaps and prorations
- Working with trial periods and grace periods
- Processing one-time charges alongside subscriptions
- Customizing invoice details and tax information

### For Advanced Users

Explore:
- Webhook event customization and extended handling
- Metered billing and usage-based pricing
- Multi-plan subscriptions (multiple subscriptions per user)
- Customer balance and credit management
- Tax ID validation and compliance
- Advanced invoice customization
- Stripe Connect integration for marketplaces
- Testing strategies for subscription flows

### Navigation Tips

- Start with the Quick Reference section for common tasks
- Check Key Concepts to understand core Cashier terminology
- Use `references/other.md` for complete implementation details
- Reference the official Laravel Cashier docs at https://laravel.com/docs/12.x/billing for the latest updates

## Environment Configuration

Required environment variables in `.env`:

```env
STRIPE_KEY=pk_test_your_stripe_publishable_key
STRIPE_SECRET=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_signing_secret
CASHIER_CURRENCY=usd
```

**Important:** Use test mode keys (pk_test_*, sk_test_*) during development and switch to live keys (pk_live_*, sk_live_*) for production.

## Common Patterns

### Complete Subscription Checkout Flow

```php
// 1. Create checkout session
public function subscribe(Request $request)
{
    return $request->user()
        ->newSubscription('default', 'price_monthly')
        ->trialDays(14)
        ->allowPromotionCodes()
        ->checkout([
            'success_url' => route('checkout.success') . '?session_id={CHECKOUT_SESSION_ID}',
            'cancel_url' => route('checkout.cancel'),
        ]);
}

// 2. Handle success
public function success(Request $request)
{
    $sessionId = $request->get('session_id');

    if ($request->user()->subscribed('default')) {
        return redirect()->route('dashboard')
            ->with('success', 'Subscription activated!');
    }
}
```

### Upgrade/Downgrade Pattern

```php
// Upgrade to annual plan with prorated credit
public function upgrade(Request $request)
{
    $subscription = $request->user()->subscription('default');

    if ($subscription->active()) {
        $subscription->swap('price_yearly');
        return back()->with('success', 'Upgraded to annual plan!');
    }
}
```

### Payment Method Update Flow

```php
// Controller: Generate setup intent
public function paymentMethods(Request $request)
{
    return view('billing.payment-methods', [
        'intent' => $request->user()->createSetupIntent(),
        'paymentMethods' => $request->user()->paymentMethods(),
    ]);
}

// View: Stripe.js integration (Blade)
<form id="payment-form" method="POST" action="{{ route('payment-method.add') }}">
    @csrf
    <div id="card-element"></div>
    <button type="submit">Add Payment Method</button>
</form>

// Controller: Store payment method
public function addPaymentMethod(Request $request)
{
    $request->user()->addPaymentMethod($request->payment_method);
    return back()->with('success', 'Payment method added!');
}
```

## Resources

### Official Documentation
- Laravel Cashier (Stripe): https://laravel.com/docs/12.x/billing
- Stripe API Documentation: https://stripe.com/docs/api
- Stripe Testing Guide: https://stripe.com/docs/testing

### Testing
Use Stripe test card numbers for development:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- Requires authentication: `4000 0025 0000 3155`

Always use test mode API keys during development and testing.

## Notes

- Cashier requires PHP 8.1+ and Laravel 10.0+
- Always configure webhooks in production for reliable subscription management
- Use Stripe test mode during development
- The Billable trait can be added to any Eloquent model, not just User
- Cashier handles most webhook events automatically
- Consider using Stripe's billing portal for customer self-service
- Reference files preserve structure and examples from official Laravel docs
- Test subscription flows thoroughly before going to production

## Updating

This skill is based on Laravel Cashier for Laravel 12.x. For the latest information, refer to the official documentation at https://laravel.com/docs/billing.
