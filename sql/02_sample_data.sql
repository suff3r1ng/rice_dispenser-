-- ================================================
-- Sample Data for Smart Rice Dispenser
-- ================================================

-- Sample settings (if none exist)
INSERT INTO settings (low_threshold_grams) 
SELECT 150 
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- Sample rice weight data
INSERT INTO rice_weight (weight_grams, level_state, timestamp) VALUES
(1500, 'full', NOW() - INTERVAL '1 hour'),
(1200, 'partial', NOW() - INTERVAL '30 minutes'),
(800, 'partial', NOW() - INTERVAL '15 minutes'),
(500, 'partial', NOW() - INTERVAL '5 minutes'),
(1600, 'full', NOW());

-- Sample dispense requests
INSERT INTO dispense_request (requested_grams, requested_cups, dispensed_grams, status, requested_at, completed_at) VALUES
(200, 1.0, 195, 'completed', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours' + INTERVAL '30 seconds'),
(400, 2.0, 405, 'completed', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour' + INTERVAL '45 seconds'),
(150, 0.75, 0, 'pending', NOW() - INTERVAL '5 minutes', NULL),
(300, 1.5, 295, 'completed', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes' + INTERVAL '1 minute');
