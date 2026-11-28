-- ORVEX ERP tenant hardening migration (2026-11-28)
-- Run against the initial ORVEX ERP schema only.
alter table public.organizations add column if not exists created_by uuid references auth.users(id) on delete set null;
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
drop policy if exists "members can view their organizations" on public.organizations;
create policy "members can view their organizations" on public.organizations for select to authenticated using (created_by=(select auth.uid()) or exists(select 1 from public.organization_members m where m.organization_id=organizations.id and m.user_id=(select auth.uid())));
create policy "owners can create organizations" on public.organizations for insert to authenticated with check (created_by=(select auth.uid()));
create policy "users can create their owner membership" on public.organization_members for insert to authenticated with check (user_id=(select auth.uid()) and role='owner' and exists(select 1 from public.organizations o where o.id=organization_members.organization_id and o.created_by=(select auth.uid())));
create or replace function public.create_organization(p_name text) returns uuid language plpgsql security invoker set search_path='' as $$
declare v_user_id uuid:=auth.uid(); v_org_id uuid; v_name text:=nullif(trim(p_name),'');
begin
 if v_user_id is null then raise exception 'Authentication required'; end if;
 if v_name is null or length(v_name)<2 or length(v_name)>120 then raise exception 'Organization name must contain 2 to 120 characters'; end if;
 insert into public.organizations(name,slug,created_by) values(v_name,regexp_replace(lower(v_name),'[^a-z0-9]+','-','g')||'-'||left(gen_random_uuid()::text,8),v_user_id) returning id into v_org_id;
 insert into public.organization_members(organization_id,user_id,role) values(v_org_id,v_user_id,'owner');
 return v_org_id;
end; $$;
revoke all on function public.create_organization(text) from public;
revoke all on function public.create_organization(text) from anon;
grant execute on function public.create_organization(text) to authenticated;
