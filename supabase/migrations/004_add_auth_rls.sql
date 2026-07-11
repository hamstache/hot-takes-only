-- Hot Takes Only — Auth + Scoped RLS
-- Prerequisites:
--   1. Enable Anonymous Sign-In in Supabase Dashboard → Authentication → Providers → Anonymous
--   2. Run migrations 001, 002, 003 first

-- ─── Auth user ID on players ──────────────────────────────────────────────────
-- Automatically populated with the caller's auth.uid() on INSERT.
-- Existing rows (from before this migration) will have NULL.

ALTER TABLE players
  ADD COLUMN auth_user_id uuid REFERENCES auth.users(id) DEFAULT auth.uid();

-- ─── Drop prototype open policies ─────────────────────────────────────────────

DROP POLICY IF EXISTS "rooms_all"       ON rooms;
DROP POLICY IF EXISTS "players_all"     ON players;
DROP POLICY IF EXISTS "submissions_all" ON submissions;

-- ─── Rooms ────────────────────────────────────────────────────────────────────

CREATE POLICY "rooms_select" ON rooms
  FOR SELECT USING (true);

CREATE POLICY "rooms_insert" ON rooms
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Any room member can update (host changes status; judge marks round over)
CREATE POLICY "rooms_update" ON rooms
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM players
      WHERE players.room_id = rooms.id
        AND players.auth_user_id = auth.uid()
    )
  );

-- ─── Players ──────────────────────────────────────────────────────────────────

CREATE POLICY "players_select" ON players
  FOR SELECT USING (true);

CREATE POLICY "players_insert" ON players
  FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- Any room member can update any player (host deals hands, updates scores/ready)
CREATE POLICY "players_update" ON players
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM players p2
      WHERE p2.room_id = players.room_id
        AND p2.auth_user_id = auth.uid()
    )
  );

-- Players can only delete their own row
CREATE POLICY "players_delete" ON players
  FOR DELETE USING (auth.uid() = auth_user_id);

-- ─── Submissions ──────────────────────────────────────────────────────────────

CREATE POLICY "submissions_select" ON submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM players
      WHERE players.room_id = submissions.room_id
        AND players.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "submissions_insert" ON submissions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM players
      WHERE players.id = submissions.player_id
        AND players.auth_user_id = auth.uid()
    )
  );

-- Any room member can update submissions (judge marks is_winner = true)
CREATE POLICY "submissions_update" ON submissions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM players
      WHERE players.room_id = submissions.room_id
        AND players.auth_user_id = auth.uid()
    )
  );

-- ─── Eviction RPC ─────────────────────────────────────────────────────────────
-- SECURITY DEFINER lets this bypass RLS to delete other players' stale rows.
-- It verifies the caller is in the room before evicting anyone.

CREATE OR REPLACE FUNCTION evict_stale_players(p_room_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM players
    WHERE room_id = p_room_id
      AND auth_user_id = auth.uid()
  ) THEN
    RETURN;
  END IF;

  DELETE FROM players
  WHERE room_id = p_room_id
    AND auth_user_id != auth.uid()
    AND last_ping < NOW() - INTERVAL '10 seconds';
END;
$$;

GRANT EXECUTE ON FUNCTION evict_stale_players TO authenticated, anon;
