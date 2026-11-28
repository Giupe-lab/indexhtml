-- ORVEX ERP initial multi-tenant schema draft
-- Review and apply only after selecting/creating a dedicated Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  created_at timestamptz not null default now()
);

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','manager','finance','sales','hr','employee')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  email text,
  phone text,
  company_name text,
  status text not null default 'active' check (status in ('active','inactive','prospect')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  title text not null,
  stage text not null default 'lead' check (stage in ('lead','contacted','qualified','proposal','negotiation','won','lost')),
  amount numeric(14,2) not null default 0,
  expected_close date,
  owner_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.finance_transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  kind text not null check (kind in ('income','expense')),
  category text not null,
  description text not null,
  amount numeric(14,2) not null check (amount >= 0),
  transaction_date date not null default current_date,
  status text not null default 'posted' check (status in ('draft','posted','void')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  sku text,
  name text not null,
  category text,
  unit_price numeric(14,2) not null default 0,
  cost_price numeric(14,2) not null default 0,
  stock_qty numeric(14,3) not null default 0,
  stock_min numeric(14,3) not null default 0,
  created_at timestamptz not null default now(),
  unique (organization_id, sku)
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  description text,
  status text not null default 'planned' check (status in ('planned','active','on_hold','completed','cancelled')),
  start_date date,
  due_date date,
  budget numeric(14,2),
  created_at timestamptz not null default now()
);

create table if not exists public.project_tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'todo' check (status in ('todo','in_progress','blocked','done')),
  priority text not null default 'medium' check (priority in ('low','medium','high','urgent')),
  assigned_user_id uuid references auth.users(id) on delete set null,
  due_date date,
  created_at timestamptz not null default now()
);

-- Enable row-level security on every tenant-owned table.
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.customers enable row level security;
alter table public.deals enable row level security;
alter table public.finance_transactions enable row level security;
alter table public.products enable row level security;
alter table public.projects enable row level security;
alter table public.project_tasks enable row level security;

-- Membership-based access. Policies are deliberately read/write scoped to organization membership.
create policy "members can view their organizations" on public.organizations
for select to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = id and m.user_id = (select auth.uid()))
);

create policy "users can view their own memberships" on public.organization_members
for select to authenticated using (user_id = (select auth.uid()));

create policy "members manage customers in org" on public.customers
for all to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = customers.organization_id and m.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.organization_members m where m.organization_id = customers.organization_id and m.user_id = (select auth.uid()))
);

create policy "members manage deals in org" on public.deals
for all to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = deals.organization_id and m.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.organization_members m where m.organization_id = deals.organization_id and m.user_id = (select auth.uid()))
);

create policy "members manage finance in org" on public.finance_transactions
for all to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = finance_transactions.organization_id and m.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.organization_members m where m.organization_id = finance_transactions.organization_id and m.user_id = (select auth.uid()))
);

create policy "members manage products in org" on public.products
for all to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = products.organization_id and m.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.organization_members m where m.organization_id = products.organization_id and m.user_id = (select auth.uid()))
);

create policy "members manage projects in org" on public.projects
for all to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = projects.organization_id and m.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.organization_members m where m.organization_id = projects.organization_id and m.user_id = (select auth.uid()))
);

create policy "members manage project tasks in org" on public.project_tasks
for all to authenticated using (
  exists (select 1 from public.organization_members m where m.organization_id = project_tasks.organization_id and m.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.organization_members m where m.organization_id = project_tasks.organization_id and m.user_id = (select auth.uid())
  )
);
