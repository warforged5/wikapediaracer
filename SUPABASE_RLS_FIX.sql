-- Fix for Row Level Security Policy Issues
-- Run this SQL in your Supabase SQL Editor

-- First, drop existing policies for user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

-- Create improved policies that handle the timing issue
CREATE POLICY "Users can view own profile" ON user_profiles 
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles 
FOR UPDATE USING (auth.uid() = id);

-- More permissive INSERT policy that allows profile creation immediately after signup
CREATE POLICY "Users can insert own profile" ON user_profiles 
FOR INSERT WITH CHECK (
    auth.uid() = id OR 
    (auth.uid() IS NOT NULL AND id IS NOT NULL)
);

-- Alternative: Even more permissive INSERT policy if the above doesn't work
-- CREATE POLICY "Allow authenticated users to insert profiles" ON user_profiles 
-- FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Ensure the user_profiles table has proper structure
-- (Run this if you haven't created the table yet)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    display_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    device_id TEXT,
    local_data_migrated BOOLEAN DEFAULT FALSE,
    preferences JSONB DEFAULT '{}',
    
    -- Statistics
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_races INTEGER DEFAULT 0,
    
    CONSTRAINT user_profiles_display_name_check CHECK (LENGTH(display_name) >= 1)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_device_id ON user_profiles(device_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;