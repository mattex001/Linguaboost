-- Lets users pick a device TTS voice for their target language.
alter table public.profiles
  add column voice_name text,
  add column voice_locale text;
