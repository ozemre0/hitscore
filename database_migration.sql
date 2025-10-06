-- Database Migration: Support Multiple User Types in Competitions
-- This migration allows all user types (athlete, coach, etc.) to participate in competitions
-- instead of restricting participation to only athletes.

-- Step 1: Add new columns to support multiple user types
ALTER TABLE organized_competition_participants 
ADD COLUMN user_id UUID REFERENCES profiles(id),
ADD COLUMN participant_role VARCHAR(20) DEFAULT 'athlete';

-- Step 2: Migrate existing data from athlete_id to user_id
UPDATE organized_competition_participants 
SET user_id = athlete_id, participant_role = 'athlete'
WHERE athlete_id IS NOT NULL;

-- Step 3: Make user_id NOT NULL after migration
ALTER TABLE organized_competition_participants 
ALTER COLUMN user_id SET NOT NULL;

-- Step 4: Add constraint to ensure participant_role is valid
ALTER TABLE organized_competition_participants 
ADD CONSTRAINT check_participant_role 
CHECK (participant_role IN ('athlete', 'coach', 'official', 'admin'));

-- Step 5: Create index for better performance
CREATE INDEX idx_organized_competition_participants_user_id 
ON organized_competition_participants(user_id);

CREATE INDEX idx_organized_competition_participants_role 
ON organized_competition_participants(participant_role);

-- Step 6: Update foreign key constraints if needed
-- (This might need to be adjusted based on your current schema)

-- Step 7: After verifying everything works, you can drop the old athlete_id column
-- WARNING: Only run this after thorough testing!
-- ALTER TABLE organized_competition_participants DROP COLUMN athlete_id;

-- Verification queries:
-- SELECT COUNT(*) FROM organized_competition_participants WHERE user_id IS NULL;
-- SELECT participant_role, COUNT(*) FROM organized_competition_participants GROUP BY participant_role;

-- Step 8: Add registration and score control flags to competitions
ALTER TABLE organized_competitions
ADD COLUMN IF NOT EXISTS registration_allowed boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS score_allowed boolean NOT NULL DEFAULT false;
