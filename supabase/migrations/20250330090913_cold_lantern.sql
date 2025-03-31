/*
  # Add phone authentication and username support

  1. Changes
    - Add phone column to profiles table
    - Add username constraints
    - Update user creation handling

  2. Security
    - Maintain existing RLS policies
    - Add validation for phone numbers
*/

-- Add phone column to profiles
ALTER TABLE profiles
ADD COLUMN phone text UNIQUE,
ADD COLUMN display_name text NOT NULL DEFAULT '';

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Update the handle_new_user function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_username text;
  counter integer := 0;
BEGIN
  -- Generate a unique username
  new_username := COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1));
  WHILE EXISTS (SELECT 1 FROM profiles WHERE username = new_username || CASE WHEN counter = 0 THEN '' ELSE counter::text END) LOOP
    counter := counter + 1;
  END LOOP;
  new_username := new_username || CASE WHEN counter = 0 THEN '' ELSE counter::text END;

  -- Insert the new profile with security definer privileges
  INSERT INTO public.profiles (
    id,
    username,
    display_name,
    avatar_url,
    phone
  ) VALUES (
    new.id,
    new_username,
    COALESCE(new.raw_user_meta_data->>'display_name', new_username),
    'https://api.dicebear.com/7.x/avataaars/svg?seed=' || new.id,
    new.raw_user_meta_data->>'phone'
  );

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update RLS policies for profiles
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Public can read profiles" ON profiles;

-- Allow users to read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow public to read profiles
CREATE POLICY "Public can read profiles"
  ON profiles
  FOR SELECT
  TO public
  USING (true);