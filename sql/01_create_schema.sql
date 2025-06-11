-- ================================================
-- Smart Rice Dispenser Database Schema
-- Generated automatically from Dart models
-- ================================================

-- Settings table
CREATE TABLE IF NOT EXISTS settings (
  id SERIAL PRIMARY KEY,
  low_threshold_grams INTEGER NOT NULL DEFAULT 100,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default settings if none exist
INSERT INTO settings (low_threshold_grams) 
SELECT 100 
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- Trigger to automatically update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_settings_updated_at 
  BEFORE UPDATE ON settings 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Rice Weight table
CREATE TABLE IF NOT EXISTS rice_weight (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  weight_grams INTEGER NOT NULL,
  level_state VARCHAR(20) NOT NULL CHECK (level_state IN ('full', 'partial', 'empty')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_rice_weight_timestamp ON rice_weight(timestamp);
CREATE INDEX IF NOT EXISTS idx_rice_weight_level_state ON rice_weight(level_state);
CREATE INDEX IF NOT EXISTS idx_rice_weight_weight_grams ON rice_weight(weight_grams);

-- Comments for documentation
COMMENT ON TABLE rice_weight IS 'Stores rice weight measurements from sensors';
COMMENT ON COLUMN rice_weight.id IS 'Unique identifier for each weight measurement';
COMMENT ON COLUMN rice_weight.timestamp IS 'When the measurement was taken';
COMMENT ON COLUMN rice_weight.weight_grams IS 'Weight measurement in grams';
COMMENT ON COLUMN rice_weight.level_state IS 'Rice level state: full, partial, or empty';

-- Dispense Request table
CREATE TABLE IF NOT EXISTS dispense_request (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requested_grams INTEGER NOT NULL,
  requested_cups DECIMAL(5,2) NOT NULL,
  dispensed_grams INTEGER DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dispense_request_status ON dispense_request(status);
CREATE INDEX IF NOT EXISTS idx_dispense_request_requested_at ON dispense_request(requested_at);
CREATE INDEX IF NOT EXISTS idx_dispense_request_completed_at ON dispense_request(completed_at);

-- Trigger to automatically set completed_at when status changes
CREATE OR REPLACE FUNCTION set_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    NEW.completed_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_dispense_request_completed_at 
  BEFORE UPDATE ON dispense_request 
  FOR EACH ROW 
  EXECUTE FUNCTION set_completed_at();

-- Comments for documentation
COMMENT ON TABLE dispense_request IS 'Stores rice dispensing requests and their status';
COMMENT ON COLUMN dispense_request.id IS 'Unique identifier for each dispense request';
COMMENT ON COLUMN dispense_request.requested_grams IS 'Amount of rice requested in grams';
COMMENT ON COLUMN dispense_request.requested_cups IS 'Amount of rice requested in cups';
COMMENT ON COLUMN dispense_request.dispensed_grams IS 'Actual amount dispensed in grams';
COMMENT ON COLUMN dispense_request.status IS 'Request status: pending, completed, or failed';

-- Create migrations tracking table
CREATE TABLE IF NOT EXISTS migrations (
  version VARCHAR(50) PRIMARY KEY,
  description TEXT NOT NULL,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE migrations IS 'Tracks database schema migrations';
