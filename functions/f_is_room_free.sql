DELIMITER $$
CREATE OR REPLACE FUNCTION f_is_room_free(
    p_room_id INT,
    p_start_time TIME,
    p_end_time TIME,
    p_dow VARCHAR(10)
) RETURNS tinyint(1)
DETERMINISTIC
BEGIN
    DECLARE conflict_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO conflict_count
    FROM section_room sr
    JOIN section s ON s.id = sr.section_id
    WHERE sr.room_id = p_room_id
      AND (
            (LOCATE('M', s.dow) > 0 AND LOCATE('M', p_dow) > 0)
         OR (LOCATE('T', s.dow) > 0 AND LOCATE('T', p_dow) > 0)
         OR (LOCATE('W', s.dow) > 0 AND LOCATE('W', p_dow) > 0)
         OR (LOCATE('R', s.dow) > 0 AND LOCATE('R', p_dow) > 0)
         OR (LOCATE('F', s.dow) > 0 AND LOCATE('F', p_dow) > 0)
      )
      AND (
          p_start_time < s.end_time
          AND p_end_time > s.start_time
      );

    RETURN (conflict_count = 0);
END$$
DELIMITER ;
