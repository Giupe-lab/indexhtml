-- ORVEX ERP initial multi-tenant schema draft
-- Review and apply only after selecting/creating a dedicated Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  created_by uuid references auth.users(id) on delete set null,
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


-- Tenant indexes
create index if not exists organization_members_user_id_idx on public.organization_members(user_id);
create index if not exists customers_organization_id_idx on public.customers(organization_id);
create index if not exists deals_organization_id_idx on public.deals(organization_id);
create index if not exists deals_customer_id_idx on public.deals(customer_id);
create index if not exists deals_owner_user_id_idx on public.deals(owner_user_id);
create index if not exists finance_transactions_organization_id_idx on public.finance_transactions(organization_id);
create index if not exists finance_transactions_created_by_idx on public.finance_transactions(created_by);
create index if not exists products_organization_id_idx on public.products(organization_id);
create index if not exists projects_organization_id_idx on public.projects(organization_id);
create index if not exists project_tasks_organization_id_idx on public.project_tasks(organization_id);
create index if not exists project_tasks_project_id_idx on public.project_tasks(project_id);
create index if not exists project_tasks_assigned_user_id_idx on public.project_tasks(assigned_user_id);

-- Membership-based access. Members can only access records belonging to their organization.
create policy "members can view their organizations" on public.organizations
for select to authenticated using (
  created_by = (select auth.uid())
  or exists (select 1 from public.organization_members m where m.organization_id = organizations.id and m.user_id = (select auth.uid()))
);
create policy "owners can create organizations" on public.organizations
for insert to authenticated with check (created_by = (select auth.uid()));
create policy "users can view their own memberships" on public.organization_members
for select to authenticated using (user_id = (select auth.uid()));
create policy "users can create their owner membership" on public.organization_members
for insert to authenticated with check (
  user_id = (select auth.uid()) and role = 'owner'
  and exists (select 1 from public.organizations o where o.id = organization_members.organization_id and o.created_by = (select auth.uid()))
);

create policy "members manage customers in org" on public.customers
for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = customers.organization_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.organization_members m where m.organization_id = customers.organization_id and m.user_id = (select auth.uid())));
create policy "members manage deals in org" on public.deals
for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = deals.organization_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.organization_members m where m.organization_id = deals.organization_id and m.user_id = (select auth.uid())));
create policy "members manage finance in org" on public.finance_transactions
for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = finance_transactions.organization_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.organization_members m where m.organization_id = finance_transactions.organization_id and m.user_id = (select auth.uid())));
create policy "members manage products in org" on public.products
for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = products.organization_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.organization_members m where m.organization_id = products.organization_id and m.user_id = (select auth.uid())));
create policy "members manage projects in org" on public.projects
for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = projects.organization_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.organization_members m where m.organization_id = projects.organization_id and m.user_id = (select auth.uid())));
create policy "members manage project tasks in org" on public.project_tasks
for all to authenticated using (exists (select 1 from public.organization_members m where m.organization_id = project_tasks.organization_id and m.user_id = (select auth.uid())))
with check (exists (select 1 from public.organization_members m where m.organization_id = project_tasks.organization_id and m.user_id = (select auth.uid())));

-- SECURITY INVOKER: creation is constrained by RLS policies above, with no privileged bypass.
create or replace function public.create_organization(p_name text)
returns uuid language plpgsql security invoker set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_org_id uuid;
  v_name text := nullif(trim(p_name), '');
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if v_name is null or length(v_name) < 2 or length(v_name) > 120 then
    raise exception 'Organization name must contain 2 to 120 characters';
  end if;
  insert into public.organizations (name, slug, created_by)
  values (v_name, regexp_replace(lower(v_name), '[^a-z0-9]+', '-', 'g') || '-' || left(gen_random_uuid()::text, 8), v_user_id)
  returning id into v_org_id;
  insert into public.organization_members (organization_id, user_id, role)
  values (v_org_id, v_user_id, 'owner');
  return v_org_id;
end;
$$;
revoke all on function public.create_organization(text) from public;
revoke all on function public.create_organization(text) from anon;
grant execute on function public.create_organization(text) to authenticated;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;
create trigger customers_set_updated_at before update on public.customers
for each row execute function public.set_updated_at();
create trigger deals_set_updated_at before update on public.deals
for each row execute function public.set_updated_at();
