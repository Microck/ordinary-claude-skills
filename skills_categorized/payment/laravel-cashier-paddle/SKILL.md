---
name: laravel-cashier-paddle
description: Laravel Cashier (Paddle) - Subscription billing and payment processing
---

# Laravel Cashier (Paddle) Skill

Comprehensive assistance with Laravel Cashier Paddle - an expressive, fluent interface to Paddle's subscription billing services for Laravel applications.

## When to Use This Skill

This skill should be triggered when:
- Implementing subscription billing with Paddle in Laravel applications
- Setting up checkout flows for products or subscriptions
- Managing subscription lifecycle (create, swap, pause, cancel)
- Handling webhook events from Paddle
- Working with customer management and payment methods
- Implementing trial periods or multi-product subscriptions
- Processing transactions, refunds, or credits
- Generating invoices or receipts
- Previewing prices with currency/tax calculations
- Debugging Paddle integration issues in Laravel

## Quick Reference

### 1. Basic Setup - Billable Model

```php
use Laravel\Paddle\Billable;

class User extends Authenticatable
{
    use Billable;

    public function paddleName(): string|null
    {
        return $this->name;
    }

    public function paddleEmail(): string|null
    {
        return $this->email;
    }
}
```

### 2. Simple Product Checkout

```php
// Create checkout session
$checkout = $user->checkout('pri_deluxe_album')
    ->returnTo(route('dashboard'));

// Display checkout button
<x-paddle-button :checkout="$checkout" class="px-8 py-4">
    Subscribe
</x-paddle-button>
```

### 3. Subscription Creation

```php
// Single subscription
$checkout = $user->subscribe('price_basic_monthly', 'default')
    ->returnTo(route('home'));

// Multi-product subscription
$checkout = $user->subscribe([
    'price_monthly',
    'price_chat' => 5  // with quantity
]);
```

### 4. Price Preview with Tax

```php
use Laravel\Paddle\Cashier;

// Preview prices for country
$prices = Cashier::previewPrices(['pri_123', 'pri_456'], [
    'address' => ['country_code' => 'BE', 'postal_code' => '1234']
]);

// Display in Blade
@foreach ($prices as $price)
    <li>{{ $price->product['name'] }} - {{ $price->total() }}</li>
    <li>Subtotal: {{ $price->subtotal() }} + Tax: {{ $price->tax() }}</li>
@endforeach
```

### 5. Subscription Status Checks

```php
// Check various subscription states
if ($user->subscribed()) { }
if ($user->subscribed('default')) { }
if ($user->subscribedToProduct('pro_basic')) { }
if ($user->subscription()->onTrial()) { }
if ($user->subscription()->onGracePeriod()) { }
if ($user->subscription()->canceled()) { }
if ($user->subscription()->pastDue()) { }
```

### 6. Plan Swapping

```php
// Immediate swap with proration
$user->subscription()->swap('pri_456');

// Swap and invoice immediately
$user->subscription()->swapAndInvoice('pri_456');

// Swap without proration
$user->subscription()->noProrate()->swap('pri_456');
```

### 7. Subscription Quantity Management

```php
// Increment/decrement quantity
$user->subscription()->incrementQuantity();
$user->subscription()->incrementQuantity(5);
$user->subscription()->decrementQuantity();

// Set specific quantity
$user->subscription()->updateQuantity(10);

// Multi-product quantity
$user->subscription()->incrementQuantity(1, 'price_chat');
```

### 8. Pause and Resume Subscriptions

```php
// Pause at period end
$user->subscription()->pause();

// Pause immediately
$user->subscription()->pauseNow();

// Pause until specific date
$user->subscription()->pauseUntil(now()->addMonth());

// Resume paused subscription
$user->subscription()->resume();
```

### 9. Webhook Event Handling

```php
use Laravel\Paddle\Events\WebhookReceived;
use Laravel\Paddle\Events\TransactionCompleted;

// Listen for specific events
Event::listen(TransactionCompleted::class, function ($event) {
    $transaction = $event->transaction;
    // Process completed transaction
});

// Handle custom webhook events
public function handle(WebhookReceived $event): void
{
    if ($event->payload['event_type'] === 'transaction.billed') {
        // Handle custom event
    }
}
```

### 10. Transaction Management

```php
// Retrieve transactions
$transactions = $user->transactions;

// Refund with specific items
$response = $transaction->refund('Accidental charge', [
    'pri_123',
    'pri_456' => 200  // partial refund amount
]);

// Full refund
$response = $transaction->refund('Customer request');

// Download invoice PDF
return $transaction->redirectToInvoicePdf();
```

## Key Concepts

### Checkout Sessions
Cashier Paddle uses checkout sessions to initiate payments. Sessions can be for one-time products, subscriptions, or guest checkouts. They support both overlay and inline display modes.

### Billable Models
Any Eloquent model can become "billable" by using the `Billable` trait. This adds subscription and payment methods to your models (typically the User model).

### Subscriptions
Subscriptions represent recurring billing arrangements. They can have multiple products, quantities, trial periods, and various lifecycle states (active, paused, canceled, on grace period).

### Transactions
Transactions represent completed payments. They include invoice data, line items, tax information, and support refunds/credits.

### Webhooks
Paddle sends webhook events for important subscription and payment events. Cashier automatically handles webhook signature verification and provides Laravel events for common webhook types.

### Proration
When swapping plans or changing quantities, Cashier can automatically calculate prorated amounts or you can disable proration using `noProrate()`.

### Grace Periods
When subscriptions are paused or canceled, they remain active until the end of the current billing period. This is called a "grace period" - the subscription is technically paused/canceled but still accessible.

## Reference Files

This skill includes comprehensive documentation in `references/`:

- **other.md** - Complete Laravel Cashier Paddle documentation including:
  - Installation and configuration steps
  - Checkout session creation (overlay, inline, guest)
  - Customer management and defaults
  - Subscription operations (create, swap, pause, cancel)
  - Multi-product and multi-subscription support
  - Trial period management
  - Quantity management and proration
  - Webhook configuration and event handling
  - Transaction history, refunds, and credits
  - Invoice generation and downloads
  - Middleware examples for subscription protection

Use `view` to read the reference file when detailed information is needed.

## Working with This Skill

### For Beginners
1. Start by understanding the **Billable** trait and how to add it to your User model
2. Learn **basic checkout** creation for simple product purchases
3. Study **subscription creation** patterns for recurring billing
4. Understand **environment configuration** (sandbox vs production)

### For Intermediate Users
1. Implement **subscription lifecycle management** (pause, resume, cancel)
2. Work with **plan swapping** and proration logic
3. Handle **webhook events** for subscription updates
4. Implement **trial periods** with or without upfront payment
5. Manage **multi-product subscriptions** with quantities

### For Advanced Users
1. Build **custom subscription middleware** for route protection
2. Implement **multi-subscription** support for different product lines
3. Create **transaction refund** and **credit** workflows
4. Customize **invoice generation** and delivery
5. Build **subscription analytics** using query scopes
6. Handle **payment method updates** with redirect flows

### Navigation Tips
- Use the Quick Reference above for common code patterns
- Check `references/other.md` for complete API documentation
- Search for specific methods like `swap()`, `pause()`, or `refund()`
- Webhook events are documented with their payload structure
- All code examples include proper error handling context

## Common Patterns

### Subscription Protection Middleware
```php
namespace App\Http\Middleware;

class Subscribed
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user()?->subscribed()) {
            return redirect('/subscribe');
        }
        return $next($request);
    }
}

Route::get('/dashboard', fn () => '...')->middleware([Subscribed::class]);
```

### Trial Management
```php
// With payment method up front
$checkout = $user->subscribe('pri_monthly')
    ->returnTo(route('home'));

// Without payment method (generic trial)
$user->createAsCustomer(['trial_ends_at' => now()->addDays(10)]);

// Extend existing trial
$user->subscription()->extendTrial(now()->addDays(5));

// Activate trial early
$user->subscription()->activate();
```

### Guest Checkout
```php
use Laravel\Paddle\Checkout;

$checkout = Checkout::guest(['pri_34567'])
    ->returnTo(route('home'));
```

## Environment Configuration

```env
PADDLE_CLIENT_SIDE_TOKEN=your-paddle-client-side-token
PADDLE_API_KEY=your-paddle-api-key
PADDLE_RETAIN_KEY=your-paddle-retain-key
PADDLE_WEBHOOK_SECRET="your-paddle-webhook-secret"
PADDLE_SANDBOX=true
CASHIER_CURRENCY_LOCALE=nl_BE
```

## Available Webhook Events

- `CustomerUpdated` - Customer information changed
- `TransactionCompleted` - Payment completed successfully
- `TransactionUpdated` - Transaction details changed
- `SubscriptionCreated` - New subscription created
- `SubscriptionUpdated` - Subscription modified
- `SubscriptionPaused` - Subscription paused
- `SubscriptionCanceled` - Subscription canceled

## Subscription Query Scopes

```php
// Filter subscriptions by status
Subscription::query()->valid();
Subscription::query()->onTrial();
Subscription::query()->active();
Subscription::query()->canceled();
Subscription::query()->paused();
Subscription::query()->onGracePeriod();
```

## Resources

### Official Documentation
- Laravel Cashier Paddle Docs: https://laravel.com/docs/cashier-paddle
- Paddle Developer Portal: https://developer.paddle.com/

### references/
Organized documentation extracted from official sources containing:
- Detailed API method explanations
- Complete code examples with context
- Webhook payload structures
- Configuration options
- Best practices and patterns

### scripts/
Add helper scripts here for:
- Webhook testing utilities
- Subscription migration scripts
- Invoice batch generation

### assets/
Add templates or examples:
- Checkout page templates
- Email notification templates
- Subscription management UI components

## Notes

- This skill was automatically generated from official Laravel Cashier Paddle documentation
- All code examples are tested patterns from the official docs
- Webhook handling includes automatic CSRF protection exemption
- Sandbox mode is enabled by default for development
- Price previews include automatic tax calculation based on customer location
- Subscriptions support both immediate and grace period cancellations
- Multi-product subscriptions allow different quantities per product

## Updating

To refresh this skill with updated documentation:
1. Re-run the scraper with the same configuration
2. The skill will be rebuilt with the latest information from Laravel docs
3. New features and API changes will be automatically incorporated
