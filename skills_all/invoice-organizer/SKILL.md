---
name: invoice-organizer
description: Organize, categorize, track, and manage invoices systematically with automated extraction of invoice data, payment tracking, and financial organization. Use when processing invoice uploads, extracting invoice details (date, amount, vendor), categorizing expenses, tracking payment status, organizing receipts, generating financial reports, or building accounting and bookkeeping systems.
---

# Invoice Organizer - Receipt Management

## When to use this skill

- Processing uploaded invoice PDFs and images
- Extracting invoice data (date, amount, vendor, items)
- Categorizing expenses and business costs
- Tracking invoice payment status
- Organizing receipts for tax purposes
- Generating financial reports from invoices
- Building expense tracking applications
- Implementing automated bookkeeping
- Creating invoice approval workflows
- Matching invoices with purchase orders
- Detecting duplicate invoices
- Building accounting and finance tools

## When to use this skill

- Organizing invoices, extracting metadata.
- When working on related tasks or features
- During development that requires this expertise

**Use when**: Organizing invoices, extracting metadata.

## Pattern
\`\`\`typescript
const invoiceDate = extractDate(filename);
const newName = `${invoiceDate}_${vendor}_${amount}.pdf`;
fs.renameSync(oldPath, newPath);
\`\`\`
