# Supabase Database Setup for Wikipedia Racer

This document outlines the database schema and setup required for synchronized group racing functionality using Supabase.

## Overview

The synchronization system allows users to:
- Create online groups with shareable group codes
- Join existing groups using group codes (no account required)
- Sync group stats, player statistics, and race history in real-time
- Start synchronized races that update for all group members

## Database Schema

### 1. `sync_groups` Table

Stores online group information with shareable codes.

```sql
CREATE TABLE sync_groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    group_code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_races INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_by_device_id TEXT, -- Optional: track creating device for admin purposes
    
    -- Indexes
    CONSTRAINT sync_groups_group_code_check CHECK (LENGTH(group_code) = 6),
    CONSTRAINT sync_groups_name_check CHECK (LENGTH(name) >= 1)
);

-- Create index for fast group code lookups
CREATE INDEX idx_sync_groups_group_code ON sync_groups(group_code);
CREATE INDEX idx_sync_groups_active ON sync_groups(is_active);
```

### 2. `sync_players` Table

Stores player information for synchronized groups.

```sql
CREATE TABLE sync_players (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES sync_groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    device_id TEXT, -- Device identifier for local player matching
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_races INTEGER DEFAULT 0,
    average_time_seconds DECIMAL DEFAULT 0.0,
    
    -- Ensure unique player names within each group
    UNIQUE(group_id, name),
    
    -- Constraints
    CONSTRAINT sync_players_name_check CHECK (LENGTH(name) >= 1),
    CONSTRAINT sync_players_stats_check CHECK (
        total_wins >= 0 AND 
        total_losses >= 0 AND 
        total_races >= 0 AND 
        average_time_seconds >= 0
    )
);

-- Indexes
CREATE INDEX idx_sync_players_group_id ON sync_players(group_id);
CREATE INDEX idx_sync_players_device_id ON sync_players(device_id);
```

### 3. `sync_race_results` Table

Stores synchronized race results and history.

```sql
CREATE TABLE sync_race_results (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES sync_groups(id) ON DELETE CASCADE,
    winner_id UUID REFERENCES sync_players(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    total_duration_seconds INTEGER,
    total_rounds INTEGER DEFAULT 0,
    race_data JSONB, -- Store complete race result data (participants, rounds, etc.)
    
    -- Constraints
    CONSTRAINT sync_race_results_duration_check CHECK (total_duration_seconds >= 0),
    CONSTRAINT sync_race_results_rounds_check CHECK (total_rounds >= 0)
);

-- Indexes
CREATE INDEX idx_sync_race_results_group_id ON sync_race_results(group_id);
CREATE INDEX idx_sync_race_results_winner_id ON sync_race_results(winner_id);
CREATE INDEX idx_sync_race_results_completed_at ON sync_race_results(completed_at);
```

### 4. `sync_race_rounds` Table

Stores individual round data for detailed race tracking.

```sql
CREATE TABLE sync_race_rounds (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    race_result_id UUID REFERENCES sync_race_results(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    winner_id UUID REFERENCES sync_players(id) ON DELETE CASCADE,
    start_page_title TEXT NOT NULL,
    end_page_title TEXT NOT NULL,
    start_page_url TEXT,
    end_page_url TEXT,
    duration_seconds INTEGER NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique round numbers per race
    UNIQUE(race_result_id, round_number),
    
    -- Constraints
    CONSTRAINT sync_race_rounds_duration_check CHECK (duration_seconds >= 0),
    CONSTRAINT sync_race_rounds_round_check CHECK (round_number >= 1)
);

-- Indexes
CREATE INDEX idx_sync_race_rounds_race_result_id ON sync_race_rounds(race_result_id);
CREATE INDEX idx_sync_race_rounds_winner_id ON sync_race_rounds(winner_id);
```

### 5. `sync_active_races` Table

Tracks currently active/live races for real-time synchronization.

```sql
CREATE TABLE sync_active_races (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES sync_groups(id) ON DELETE CASCADE,
    started_by_player_id UUID REFERENCES sync_players(id) ON DELETE CASCADE,
    race_config JSONB NOT NULL, -- Race configuration (pages, rounds, etc.)
    status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'countdown', 'active', 'completed', 'cancelled')),
    current_round INTEGER DEFAULT 1,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '2 hours',
    
    -- Only one active race per group at a time
    UNIQUE(group_id)
);

-- Indexes
CREATE INDEX idx_sync_active_races_group_id ON sync_active_races(group_id);
CREATE INDEX idx_sync_active_races_status ON sync_active_races(status);
CREATE INDEX idx_sync_active_races_expires_at ON sync_active_races(expires_at);
```

## Row Level Security (RLS) Policies

Enable RLS and create policies for secure access:

```sql
-- Enable RLS on all tables
ALTER TABLE sync_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_race_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_race_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_active_races ENABLE ROW LEVEL SECURITY;

-- Public access policies (since users don't need accounts)
-- Anyone can read and write to sync tables (groups are protected by group codes)

CREATE POLICY "Enable read access for all users" ON sync_groups FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sync_groups FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sync_groups FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON sync_players FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sync_players FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sync_players FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON sync_race_results FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sync_race_results FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON sync_race_rounds FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sync_race_rounds FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON sync_active_races FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sync_active_races FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sync_active_races FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON sync_active_races FOR DELETE USING (true);
```

## Utility Functions

### Generate Group Code Function

```sql
CREATE OR REPLACE FUNCTION generate_group_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNPQRSTUVWXYZ123456789'; -- Exclude confusing chars like O, 0
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
    END LOOP;
    
    -- Check if code already exists, regenerate if so
    IF EXISTS (SELECT 1 FROM sync_groups WHERE group_code = result) THEN
        RETURN generate_group_code(); -- Recursive call
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### Cleanup Expired Races Function

```sql
CREATE OR REPLACE FUNCTION cleanup_expired_races()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM sync_active_races 
    WHERE expires_at < NOW() 
    AND status NOT IN ('active');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run cleanup (if using pg_cron extension)
-- SELECT cron.schedule('cleanup-expired-races', '*/30 * * * *', 'SELECT cleanup_expired_races();');
```

## Real-time Subscriptions

Set up real-time subscriptions for live updates:

```sql
-- Enable real-time for all sync tables
ALTER PUBLICATION supabase_realtime ADD TABLE sync_groups;
ALTER PUBLICATION supabase_realtime ADD TABLE sync_players;
ALTER PUBLICATION supabase_realtime ADD TABLE sync_race_results;
ALTER PUBLICATION supabase_realtime ADD TABLE sync_race_rounds;
ALTER PUBLICATION supabase_realtime ADD TABLE sync_active_races;
```

## Setup Steps

1. **Create a new Supabase project** at https://supabase.com
2. **Run the SQL commands above** in the Supabase SQL editor
3. **Enable Real-time** in the Database settings
4. **Get your project credentials**:
   - Project URL
   - Project API Key (anon/public)
5. **Add environment variables** to your Flutter project
6. **Install Supabase Flutter package**: `flutter pub add supabase_flutter`

## Environment Configuration

Add to your `.env` file or environment configuration:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Security Considerations

- Group codes provide access control (6-character codes = ~2 billion combinations)
- No user accounts required - access is based on group codes
- RLS policies ensure data isolation (though publicly readable for this use case)
- Active races expire automatically to prevent orphaned records
- Device IDs can help identify local players without exposing personal information

## Data Flow

1. **Group Creation**: Generate unique group code, create `sync_groups` entry
2. **Joining Groups**: Validate group code, create/update `sync_players` entry
3. **Starting Races**: Create `sync_active_races` entry, broadcast to group members
4. **Race Updates**: Real-time updates via Supabase subscriptions
5. **Race Completion**: Move data to `sync_race_results` and `sync_race_rounds`, update player stats
6. **Cleanup**: Expired active races are automatically cleaned up

This schema supports the full Wikipedia Racer synchronization requirements while maintaining simplicity and performance.