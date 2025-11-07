DELIMITER $$

CREATE FUNCTION get_enrollment_count(section_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE enrolled_count INT DEFAULT 0;

    -- Count students currently enrolled
    SELECT COUNT(*) 
    INTO enrolled_count
    FROM enrollment e
    WHERE e.section_id = section_id;

    RETURN enrolled_count;
END$$

DELIMITER ;