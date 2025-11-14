DELIMITER $$
CREATE FUNCTION f_get_available_seats(p_sectionId INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_total_capacity INT DEFAULT 0;
    DECLARE v_enrolled_count INT DEFAULT 0;
    DECLARE v_available INT DEFAULT 0;

    -- Sum total room capacity for the section
    SELECT IFNULL(SUM(r.capacity), 0)
    INTO v_total_capacity
    FROM section_room sr
    JOIN room r ON sr.room_id = r.id
    WHERE sr.section_id = p_sectionId;

    -- Count students currently enrolled
    SELECT COUNT(*) 
    INTO v_enrolled_count
    FROM enrollment e
    WHERE e.section_id = p_sectionId;

    -- Calculate remaining seats
    SET v_available = v_total_capacity - v_enrolled_count;

    -- Prevent negatives
    IF v_available < 0 THEN
        SET v_available = 0;
    END IF;

    RETURN v_available;
END$$

DELIMITER ;
