-- Bidirectional translation: users can now pick their own spoken ("source")
-- language, not just the language they're learning.
alter table public.profiles
  add column source_language text not null default 'en';
