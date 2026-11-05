-- MealMesh: demo queries

-- Q1. Urgency ranking: available listings with hours left, most urgent first
SELECT listing_id, category_name, quantity, unit, provider_org,
       ROUND(EXTRACT(EPOCH FROM (usable_by - NOW())) / 3600, 1) AS hours_left
FROM available_listings_view
ORDER BY usable_by;

-- Q2. Listings expiring in the next 6 hours (still unclaimed)
SELECT listing_id, quantity, unit, usable_by
FROM SurplusListings
WHERE status = 'available' AND usable_by BETWEEN NOW() AND NOW() + INTERVAL '6 hours';

-- Q3. Top providers by completed claims (JOIN + GROUP BY + HAVING)
SELECT u.org_name, COUNT(c.claim_id) AS completed_claims
FROM Users u
JOIN SurplusListings sl ON sl.provider_id = u.user_id
JOIN Claims c ON c.listing_id = sl.listing_id AND c.status = 'completed'
GROUP BY u.org_name
HAVING COUNT(c.claim_id) >= 1
ORDER BY completed_claims DESC;

-- Q4. Average rating per provider (LEFT JOIN so unreviewed providers show too)
SELECT u.org_name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.review_id) AS reviews
FROM Users u
LEFT JOIN SurplusListings sl ON sl.provider_id = u.user_id
LEFT JOIN Claims c  ON c.listing_id = sl.listing_id
LEFT JOIN Reviews r ON r.claim_id = c.claim_id
WHERE u.role = 'provider'
GROUP BY u.org_name
ORDER BY avg_rating DESC NULLS LAST;

-- Q5. Nested: recipients who have never claimed anything
SELECT name, org_name FROM Users
WHERE role = 'recipient'
  AND user_id NOT IN (SELECT recipient_id FROM Claims);

-- Q6. Nested: listings larger than the average listing in the same category
SELECT sl.listing_id, fc.name, sl.quantity
FROM SurplusListings sl
JOIN FoodCategories fc ON fc.category_id = sl.category_id
WHERE sl.quantity > (SELECT AVG(quantity) FROM SurplusListings s2
                     WHERE s2.category_id = sl.category_id);

-- Q7. Community impact: total food delivered by category
SELECT fc.name, SUM(sl.quantity) AS total_delivered
FROM SurplusListings sl
JOIN FoodCategories fc ON fc.category_id = sl.category_id
WHERE sl.status = 'delivered'
GROUP BY fc.name;
