-- MealMesh: schema (PostgreSQL)
-- Authors: Nandika Gupta (PES2UG24CS303), Tanvi Magalur (PES2UG24CS257)

DROP VIEW  IF EXISTS available_listings_view;
DROP TABLE IF EXISTS Reviews, Claims, SurplusListings, Users, FoodCategories CASCADE;

CREATE TABLE FoodCategories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'provider', 'recipient')),
    org_name VARCHAR(150),
    phone VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE SurplusListings (
    listing_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    provider_id INT NOT NULL,
    quantity DECIMAL(8,2) NOT NULL CHECK (quantity > 0),
    unit VARCHAR(20) NOT NULL,
    usable_by TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available'
        CHECK (status IN ('available', 'claimed', 'expired', 'delivered')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_listing_category FOREIGN KEY (category_id)
        REFERENCES FoodCategories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_listing_provider FOREIGN KEY (provider_id)
        REFERENCES Users(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_usable_after_created CHECK (usable_by > created_at)
);

-- NOTE: listing_id is NOT globally UNIQUE here (see partial index below),
-- so a cancelled claim does not block the listing from being claimed again.
CREATE TABLE Claims (
    claim_id SERIAL PRIMARY KEY,
    listing_id INT NOT NULL,
    recipient_id INT NOT NULL,
    claimed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    pickup_time TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'completed', 'cancelled')),
    CONSTRAINT fk_claim_listing FOREIGN KEY (listing_id)
        REFERENCES SurplusListings(listing_id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_recipient FOREIGN KEY (recipient_id)
        REFERENCES Users(user_id) ON DELETE RESTRICT
);

-- One ACTIVE (non-cancelled) claim per listing = "one-recipient-only"
CREATE UNIQUE INDEX uq_active_claim_per_listing
    ON Claims(listing_id) WHERE status <> 'cancelled';

CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    claim_id INT NOT NULL UNIQUE,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment VARCHAR(300),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_review_claim FOREIGN KEY (claim_id)
        REFERENCES Claims(claim_id) ON DELETE CASCADE
);

CREATE INDEX idx_listings_status    ON SurplusListings(status);
CREATE INDEX idx_listings_usable_by ON SurplusListings(usable_by);
CREATE INDEX idx_listings_category  ON SurplusListings(category_id);
CREATE INDEX idx_claims_status      ON Claims(status);

CREATE VIEW available_listings_view AS
SELECT sl.listing_id, fc.name AS category_name, sl.quantity, sl.unit,
       sl.usable_by, u.name AS provider_name, u.org_name AS provider_org
FROM SurplusListings sl
JOIN FoodCategories fc ON fc.category_id = sl.category_id
JOIN Users u ON u.user_id = sl.provider_id
WHERE sl.status = 'available' AND sl.usable_by > NOW()
ORDER BY sl.usable_by ASC;

INSERT INTO FoodCategories (name) VALUES
    ('Bakery'), ('Produce'), ('Cooked Meals'), ('Dairy'), ('Packaged Goods'), ('Other');

-- ALTER / DROP demonstrations (as run in the Neon SQL editor)
ALTER TABLE Users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE Reviews ALTER COLUMN comment TYPE VARCHAR(500);
DROP INDEX idx_claims_status;
