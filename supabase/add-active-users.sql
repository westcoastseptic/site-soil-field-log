-- Run once in Supabase SQL Editor (New snippet > paste > Run). Adds active-user counting for app v0.22.
-- Already included at the end of setup.sql for new projects.

-- 5. Active-user counting (added 2026-11-21, app v0.22).
--    The app calls log_activity() at most once a day per user while online.
--    Stores only the account and the date (Vancouver time). Users can't read or write the table directly.
--    Rows are deleted with the account, and anything older than 3 years is removed automatically.
create table if not exists public.app_activity (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  primary key (user_id, day)
);
create index if not exists app_activity_day_idx on public.app_activity(day);
alter table public.app_activity enable row level security;
revoke all on public.app_activity from anon, authenticated;

create or replace function public.log_activity()
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then return; end if;
  insert into public.app_activity(user_id, day)
    values (auth.uid(), (now() at time zone 'America/Vancouver')::date)
    on conflict do nothing;
  delete from public.app_activity where day < ((now() at time zone 'America/Vancouver') - interval '3 years')::date;
end; $$;
revoke execute on function public.log_activity() from public, anon;
grant execute on function public.log_activity() to authenticated;

-- Active-user reports (run any time in SQL Editor):
-- Monthly active users, last 30 days:
--   select count(distinct user_id) as mau from public.app_activity where day > current_date - 30;
-- Active users by calendar month:
--   select to_char(day, 'YYYY-MM') as month, count(distinct user_id) as active_users
--   from public.app_activity group by 1 order by 1 desc;
-- Daily active users, last 30 days:
--   select day, count(*) as dau from public.app_activity where day > current_date - 30 group by day order by day desc;
