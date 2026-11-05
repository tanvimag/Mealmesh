-- MealMesh: business logic (functions, triggers)

-- 1) Atomic claim: row lock guarantees only one recipient wins a race.
CREATE OR REPLACE FUNCTION claim_listing(p_listing_id INT, p_recipient_id INT,
                                         p_pickup TIMESTAMP DEFAULT NULL)
RETURNS INT AS $$
DECLARE
    v_status VARCHAR; v_usable TIMESTAMP; v_claim_id INT;
BEGIN
    SELECT status, usable_by INTO v_status, v_usable
    FROM SurplusListings WHERE listing_id = p_listing_id
    FOR UPDATE;                                   -- lock the listing row

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Listing % does not exist', p_listing_id;
    END IF;
    IF v_status <> 'available' THEN
        RAISE EXCEPTION 'Listing % is not available (status: %)', p_listing_id, v_status;
    END IF;
    IF v_usable <= NOW() THEN
        UPDATE SurplusListings SET status = 'expired' WHERE listing_id = p_listing_id;
        RAISE EXCEPTION 'Listing % has expired', p_listing_id;
    END IF;

    INSERT INTO Claims (listing_id, recipient_id, pickup_time)
    VALUES (p_listing_id, p_recipient_id, p_pickup)
    RETURNING claim_id INTO v_claim_id;

    UPDATE SurplusListings SET status = 'claimed' WHERE listing_id = p_listing_id;
    RETURN v_claim_id;
END;
$$ LANGUAGE plpgsql;

-- 2) Providers must be providers, recipients must be recipients.
CREATE OR REPLACE FUNCTION trg_check_listing_provider() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT role FROM Users WHERE user_id = NEW.provider_id) <> 'provider' THEN
        RAISE EXCEPTION 'User % is not a provider', NEW.provider_id;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER check_listing_provider
BEFORE INSERT ON SurplusListings
FOR EACH ROW EXECUTE FUNCTION trg_check_listing_provider();

CREATE OR REPLACE FUNCTION trg_check_claim_recipient() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT role FROM Users WHERE user_id = NEW.recipient_id) <> 'recipient' THEN
        RAISE EXCEPTION 'User % is not a recipient', NEW.recipient_id;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER check_claim_recipient
BEFORE INSERT ON Claims
FOR EACH ROW EXECUTE FUNCTION trg_check_claim_recipient();

-- 3) Reviews only allowed on completed claims.
CREATE OR REPLACE FUNCTION trg_review_needs_completed() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT status FROM Claims WHERE claim_id = NEW.claim_id) <> 'completed' THEN
        RAISE EXCEPTION 'Claim % is not completed; cannot review', NEW.claim_id;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER review_needs_completed
BEFORE INSERT ON Reviews
FOR EACH ROW EXECUTE FUNCTION trg_review_needs_completed();

-- 4) Keep listing status in sync with claim status.
CREATE OR REPLACE FUNCTION trg_sync_listing_status() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
        UPDATE SurplusListings SET status = 'delivered' WHERE listing_id = NEW.listing_id;
    ELSIF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
        UPDATE SurplusListings
        SET status = CASE WHEN usable_by > NOW() THEN 'available' ELSE 'expired' END
        WHERE listing_id = NEW.listing_id;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER sync_listing_status
AFTER UPDATE OF status ON Claims
FOR EACH ROW EXECUTE FUNCTION trg_sync_listing_status();

-- 5) Mark past-due, unclaimed listings as expired (run periodically / from the app).
CREATE OR REPLACE FUNCTION expire_listings() RETURNS INT AS $$
DECLARE n INT;
BEGIN
    UPDATE SurplusListings SET status = 'expired'
    WHERE status = 'available' AND usable_by <= NOW();
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END; $$ LANGUAGE plpgsql;
