-- ================================================
-- Database Statistics and Analysis Queries
-- ================================================

-- Table sizes and record counts
SELECT 
  'settings' as table_name, 
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('settings')) as table_size
FROM settings
UNION ALL
SELECT 
  'rice_weight' as table_name, 
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('rice_weight')) as table_size
FROM rice_weight
UNION ALL
SELECT 
  'dispense_request' as table_name, 
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('dispense_request')) as table_size
FROM dispense_request;

-- Recent activity summary (last 24 hours)
SELECT 
  'Recent rice weights' as activity,
  COUNT(*) as count,
  MIN(timestamp) as earliest,
  MAX(timestamp) as latest
FROM rice_weight 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
  'Recent dispense requests' as activity,
  COUNT(*) as count,
  MIN(requested_at) as earliest,
  MAX(requested_at) as latest
FROM dispense_request 
WHERE requested_at >= NOW() - INTERVAL '24 hours';

-- Rice level distribution
SELECT 
  level_state,
  COUNT(*) as count,
  ROUND(AVG(weight_grams), 2) as avg_weight_grams,
  MIN(weight_grams) as min_weight_grams,
  MAX(weight_grams) as max_weight_grams
FROM rice_weight 
GROUP BY level_state
ORDER BY level_state;

-- Dispense request status summary
SELECT 
  status,
  COUNT(*) as count,
  ROUND(AVG(requested_grams), 2) as avg_requested_grams,
  ROUND(AVG(dispensed_grams), 2) as avg_dispensed_grams,
  ROUND(AVG(CASE WHEN dispensed_grams > 0 THEN ABS(requested_grams - dispensed_grams) END), 2) as avg_accuracy_diff
FROM dispense_request 
GROUP BY status
ORDER BY status;

-- Recent weight trends (last 10 measurements)
SELECT 
  timestamp,
  weight_grams,
  level_state,
  LAG(weight_grams) OVER (ORDER BY timestamp) as previous_weight,
  weight_grams - LAG(weight_grams) OVER (ORDER BY timestamp) as weight_change
FROM rice_weight 
ORDER BY timestamp DESC 
LIMIT 10;
