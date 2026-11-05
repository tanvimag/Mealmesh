-- MealMesh: sample data
INSERT INTO Users (name, email, password_hash, role, org_name, phone) VALUES
 ('Admin One',    'admin@mealmesh.org',    'hash_admin', 'admin',     'MealMesh',           '9000000000'),
 ('Priya Sharma', 'priya@sweetoven.com',   'hash_p1',    'provider',  'Sweet Oven Bakery',  '9000000001'),
 ('Ravi Kumar',   'ravi@freshmart.com',    'hash_p2',    'provider',  'FreshMart Grocers',  '9000000002'),
 ('Meera Nair',   'meera@pescanteen.in',   'hash_p3',    'provider',  'PES Campus Canteen', '9000000003'),
 ('Arjun Rao',    'arjun@helpinghands.org','hash_r1',    'recipient', 'Helping Hands NGO',  '9000000004'),
 ('Sana Khan',    'sana@annadaan.org',     'hash_r2',    'recipient', 'Annadaan Trust',     '9000000005'),
 ('Vikram Joshi', 'vikram@shelter.org',    'hash_r3',    'recipient', 'City Shelter',       '9000000006');

-- Active listings (providers are user_id 2,3,4)
INSERT INTO SurplusListings (category_id, provider_id, quantity, unit, usable_by) VALUES
 (1, 2,  5.0, 'kg',     NOW() + INTERVAL '3 hours'),
 (3, 4, 40.0, 'meals',  NOW() + INTERVAL '5 hours'),
 (2, 3, 12.5, 'kg',     NOW() + INTERVAL '1 day'),
 (4, 3, 20.0, 'litres', NOW() + INTERVAL '2 days'),
 (5, 3, 30.0, 'packs',  NOW() + INTERVAL '10 days');

-- Historical listings (created in the past so CHECK usable_by > created_at holds)
INSERT INTO SurplusListings (category_id, provider_id, quantity, unit, usable_by, status, created_at) VALUES
 (1, 2,  8.0, 'kg',    NOW() - INTERVAL '2 days',  'delivered', NOW() - INTERVAL '3 days'),
 (3, 4, 25.0, 'meals', NOW() - INTERVAL '1 day',   'delivered', NOW() - INTERVAL '2 days'),
 (2, 3,  6.0, 'kg',    NOW() - INTERVAL '5 hours', 'expired',   NOW() - INTERVAL '1 day');

-- Past completed claims (listings 6,7) + reviews
INSERT INTO Claims (listing_id, recipient_id, claimed_at, pickup_time, status) VALUES
 (6, 5, NOW() - INTERVAL '2.5 days', NOW() - INTERVAL '2.2 days', 'completed'),
 (7, 6, NOW() - INTERVAL '1.5 days', NOW() - INTERVAL '1.2 days', 'completed');

INSERT INTO Reviews (claim_id, rating, comment) VALUES
 (1, 5, 'Fresh bread, smooth pickup.'),
 (2, 4, 'Meals were warm, slightly late handover.');

-- Live claim via the atomic function (listing 1 -> claimed)
SELECT claim_listing(1, 5, (NOW() + INTERVAL '1 hour')::timestamp);
