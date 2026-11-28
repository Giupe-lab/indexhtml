# ORVEX ERP — Enterprise Management Platform

ORVEX is a premium multi-module ERP concept designed as a showcase product within the Nexora portfolio.

## Current prototype
- Responsive enterprise dashboard (sample data clearly marked)
- Sidebar navigation across ERP module areas
- Overview KPI cards, revenue chart, category chart, transactions, activity feed
- Interactive module navigation and demo toast feedback

## Modules in roadmap
- Executive dashboard
- Sales & CRM
- Finance
- Inventory & procurement
- Projects & operations
- HR
- Analytics
- Settings, roles and audit trail

## Structure
- `erp/index.html`: standalone visual prototype
- `erp/database/schema.sql`: draft multi-tenant Postgres schema for a dedicated Supabase project

## Important
The dashboard currently uses illustrative data and is not connected to a database. The SQL schema is a draft and has **not** been applied. Create a dedicated Supabase project for ORVEX ERP; do not reuse unrelated projects. Before production, review/strengthen membership management, role-level authorization, RLS policies, auditing, validation, backup, and financial compliance.

## Open locally
Open `erp/index.html` in a browser to preview the prototype.
