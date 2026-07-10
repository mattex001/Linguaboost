-- Daily review cap: users choose how many phrases they review per day (2-10).
-- reviews_completed_today + reviews_completed_date mirror the streak_count /
-- last_active_date pattern — a counter plus the date it's valid for, reset by
-- date comparison client-side rather than a scheduled job.
alter table public.profiles
  add column daily_review_limit integer not null default 5,
  add column reviews_completed_today integer not null default 0,
  add column reviews_completed_date date;
