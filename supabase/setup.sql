-- Site & Soil Field Log: sign-in records and security rules.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.
-- Safe to run again (it only creates what is missing and replaces the rules).

-- 1. Terms acceptance log: one row each time someone agrees to a terms version.
create table if not exists public.terms_acceptances (
  id            bigint generated always as identity primary key,
  user_id       uuid default auth.uid() references auth.users(id) on delete set null,
  email         text not null default lower(auth.jwt() ->> 'email'),
  terms_version text not null check (length(terms_version) <= 40),
  accepted_at   timestamptz not null,               -- when they tapped "I agree" (phone clock)
  recorded_at   timestamptz not null default now(), -- when the server received it
  app_version   text check (length(app_version) <= 20)
);
create index if not exists terms_acceptances_user_idx on public.terms_acceptances(user_id);

-- 2. Security rules: users can add their own record and read only their own records.
--    No one can edit or delete records from the app. You see everything in the dashboard.
alter table public.terms_acceptances enable row level security;
revoke all on public.terms_acceptances from anon;
revoke update, delete, truncate on public.terms_acceptances from authenticated;
grant select, insert on public.terms_acceptances to authenticated;

drop policy if exists "insert own acceptance" on public.terms_acceptances;
create policy "insert own acceptance" on public.terms_acceptances
  for insert to authenticated
  with check (user_id = auth.uid() and email = lower(auth.jwt() ->> 'email'));

drop policy if exists "read own acceptances" on public.terms_acceptances;
create policy "read own acceptances" on public.terms_acceptances
  for select to authenticated
  using (user_id = auth.uid());

-- 3. "Delete account" button in the app. Removes the sign-in account only;
--    acceptance records stay (user_id becomes empty, email kept) as proof of agreement.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  delete from auth.users where id = auth.uid();
end; $$;
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- 4. Handy queries for you (run any time in SQL Editor):
-- How many accounts:            select count(*) from auth.users;
-- Accounts with sign-up date:   select email, created_at, last_sign_in_at from auth.users order by created_at desc;
-- Who accepted which terms:     select email, terms_version, accepted_at, app_version from public.terms_acceptances order by accepted_at desc;
-- Accounts that haven't accepted the current terms:
--   select u.email from auth.users u where not exists (select 1 from public.terms_acceptances a where a.user_id = u.id and a.terms_version = '1.1');
