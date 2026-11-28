# ORVEX ERP — Enterprise Management Platform

ORVEX is a multi-tenant ERP showcase product in the Nexora portfolio.

## Live application
- Responsive enterprise dashboard with the approved dark navy / indigo / green visual system.
- Supabase Auth email/password sign-up and sign-in.
- First-login organization creation with owner membership.
- Live CRUD modules: CRM customers and opportunities, finance transactions, inventory products, projects and project tasks.
- Overview KPIs and analytics are calculated from the signed-in organization's records.
- Organization-scoped Row Level Security on all tenant data tables.

## Architecture
- `index.html`: application shell and design system.
- `app.js`: browser application, Supabase client, authentication and module workflows.
- `database/schema.sql`: complete initial schema for a fresh ORVEX database.
- `database/migrations/20261128_tenant_hardening.sql`: security and onboarding changes applied to the ORVEX Supabase project.

## Backend
Dedicated Supabase project: `gumdmiqarhbcsjqhimei` (EU West, Ireland).
Only the public publishable key is used by the browser. The service-role key is never included in client code.
All tenant tables have RLS enabled. The organization bootstrap function is SECURITY INVOKER and its inserts are constrained by RLS.

## Current scope and limitations
- CRM, finance, inventory and project records support create, read, update and delete.
- HR currently shows the signed-in workspace owner only; invitation and role administration are not yet enabled.
- Finance is an operational transaction register, not certified accounting or electronic invoicing.
- Authentication email confirmation and the production redirect allow-list must be configured for the published Pages URL before external onboarding.
- This is an active product build, not yet certified for production use with sensitive company data. Before commercial launch, complete role-level authorization, invitations, audit logs, backups, validation, privacy/compliance review and end-to-end testing.

## Development
Open `index.html` through the published GitHub Pages URL. The Supabase client dependency is pinned to version 2.49.1.
