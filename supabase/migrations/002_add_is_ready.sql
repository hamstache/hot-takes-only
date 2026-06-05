-- Add per-player ready flag for coordinated round advancement
ALTER TABLE players ADD COLUMN is_ready BOOLEAN NOT NULL DEFAULT FALSE;
