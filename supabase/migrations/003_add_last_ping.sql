ALTER TABLE players ADD COLUMN last_ping timestamptz DEFAULT now();
