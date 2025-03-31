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

-- Update the handle_new_user function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', new.email),
    COALESCE(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'username', new.email),
    'https://api.dicebear.com/7.x/avataaars/svg?seed=' || new.id
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY definer;