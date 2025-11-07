DELIMITER $$

CREATE FUNCTION get_available_seats(sectionId INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_capacity INT DEFAULT 0;
    DECLARE enrolled_count INT DEFAULT 0;
    DECLARE available INT DEFAULT 0;

    -- Sum total room capacity for the section
    SELECT IFNULL(SUM(r.capacity), 0)
    INTO total_capacity
    FROM section_room sr
    JOIN room r ON sr.room_id = r.id
    WHERE sr.section_id = sectionId;

    -- Count students currently enrolled
    SELECT COUNT(*) 
    INTO enrolled_count
    FROM enrollment e
    WHERE e.section_id = sectionId;

    -- Calculate remaining seats
    SET available = total_capacity - enrolled_count;

    -- Prevent negatives
    IF available < 0 THEN
        SET available = 0;
    END IF;

    RETURN available;
END$$

DELIMITER ;