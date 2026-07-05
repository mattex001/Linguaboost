-- The app's live UI (profile header, phrasebook list, due counts) subscribes
-- via supabase_flutter .stream(), which needs these tables in the realtime
-- publication. Without this the subscription errors after the initial fetch
-- and the streams flap between data and error.

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.phrases;
