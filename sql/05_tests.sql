-- MealMesh: constraint/trigger tests. T1-T4 should each raise an error.
-- Run one at a time and screenshot the error for the report.
-- (IDs assume a fresh run of 01-03: listing 1 is claimed by claim 3.)

-- T1: double-claim an already-claimed listing -> error
SELECT claim_listing(1, 6);

-- T2: claim an expired listing -> error
SELECT claim_listing(8, 6);

-- T3: review a claim that is not completed -> error (claim 3 is pending)
INSERT INTO Reviews (claim_id, rating) VALUES (3, 5);

-- T4: a recipient posting a listing -> error
INSERT INTO SurplusListings (category_id, provider_id, quantity, unit, usable_by)
VALUES (1, 5, 1, 'kg', NOW() + INTERVAL '1 day');

-- T5: cancel the claim -> listing returns to 'available' and can be re-claimed
UPDATE Claims SET status = 'cancelled' WHERE claim_id = 3;
SELECT listing_id, status FROM SurplusListings WHERE listing_id = 1;
SELECT claim_listing(1, 7);
