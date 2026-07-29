create table if not exists public.player_progress (
    user_id uuid primary key references auth.users(id) on delete cascade,
    save_version integer not null default 1,
    total_coins bigint not null default 0 check (total_coins >= 0),
    total_distance bigint not null default 0 check (total_distance >= 0),
    best_distance bigint not null default 0 check (best_distance >= 0),
    selected_character_id text not null default 'ethan',
    owned_character_ids text[] not null default array['ethan']::text[],
    sound_enabled boolean not null default true,
    updated_at timestamptz not null default now()
);

alter table public.player_progress enable row level security;

revoke all on table public.player_progress from anon;
grant select, insert, update, delete on table public.player_progress to authenticated;

drop policy if exists "Players can read their own progress" on public.player_progress;
create policy "Players can read their own progress"
on public.player_progress for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Players can create their own progress" on public.player_progress;
create policy "Players can create their own progress"
on public.player_progress for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Players can update their own progress" on public.player_progress;
create policy "Players can update their own progress"
on public.player_progress for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Players can delete their own progress" on public.player_progress;
create policy "Players can delete their own progress"
on public.player_progress for delete
to authenticated
using ((select auth.uid()) = user_id);
