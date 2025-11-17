-- Function to get the current grade of a student in a specific section
DROP FUNCTION IF EXISTS f_get_current_grade;

DELIMITER $$
CREATE FUNCTION f_get_current_grade(student_id INT, section_id INT)
RETURNS VARCHAR(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_enrollment_id INT;
    DECLARE weighted DECIMAL(6,3);
    DECLARE final_letter VARCHAR(1);

    DECLARE hw INT;
    DECLARE qz INT;
    DECLARE pr INT;
    DECLARE mt INT;
    DECLARE fe INT;
    DECLARE pt INT;


    -- Get enrollment
	SELECT 
		e.id
	INTO v_enrollment_id FROM
		enrollment e
	WHERE
		e.student_id = student_id
			AND e.section_id = section_id
	LIMIT 1;


    IF v_enrollment_id IS NULL THEN
        RETURN NULL;
    END IF;


    -- Convert letter to numeric points
    SET hw = (
        SELECT CASE letter WHEN 'A' THEN 4 WHEN 'B' THEN 3 
              WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END
        FROM grade
        WHERE enrollment_id = v_enrollment_id AND type = 1
    );

    SET qz = (
        SELECT CASE letter WHEN 'A' THEN 4 WHEN 'B' THEN 3 
              WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END
        FROM grade
        WHERE enrollment_id = v_enrollment_id AND type = 2
        LIMIT 1
    );

    SET pr = (
        SELECT CASE letter WHEN 'A' THEN 4 WHEN 'B' THEN 3 
              WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END
        FROM grade
        WHERE enrollment_id = v_enrollment_id AND type = 3
        LIMIT 1
    );

    SET mt = (
        SELECT CASE letter WHEN 'A' THEN 4 WHEN 'B' THEN 3 
              WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END
        FROM grade
        WHERE enrollment_id = v_enrollment_id AND type = 4
        LIMIT 1
    );

    SET fe = (
        SELECT CASE letter WHEN 'A' THEN 4 WHEN 'B' THEN 3 
              WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END
        FROM grade
        WHERE enrollment_id = v_enrollment_id AND type = 5
        LIMIT 1
    );

    SET pt = (
        SELECT CASE letter WHEN 'A' THEN 4 WHEN 'B' THEN 3 
              WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END
        FROM grade
        WHERE enrollment_id = v_enrollment_id AND type = 6
        LIMIT 1
    );

    -- Weighted numeric grade (0–4 scale)
    SET weighted = (
        COALESCE(hw * 0.20, 0) +
        COALESCE(qz * 0.10, 0) +
        COALESCE(pr * 0.20, 0) +
        COALESCE(mt * 0.20, 0) +
        COALESCE(pt * 0.05, 0) +
        COALESCE(fe * 0.25, 0)
    ) / NULLIF(
        (CASE WHEN hw IS NOT NULL THEN 0.20 ELSE 0 END) +
        (CASE WHEN qz IS NOT NULL THEN 0.10 ELSE 0 END) +
        (CASE WHEN pr IS NOT NULL THEN 0.20 ELSE 0 END) +
        (CASE WHEN mt IS NOT NULL THEN 0.20 ELSE 0 END) +
        (CASE WHEN pt IS NOT NULL THEN 0.05 ELSE 0 END) +
        (CASE WHEN fe IS NOT NULL THEN 0.25 ELSE 0 END), 0
    );

    -- Convert weighted numeric back to letter
    IF weighted IS NULL THEN
        RETURN NULL;
    END IF;

    SET final_letter = CASE
        WHEN weighted >= 3.6 THEN 'A'
        WHEN weighted >= 2.6 THEN 'B'
        WHEN weighted >= 1.6 THEN 'C'
        WHEN weighted >= 0.6 THEN 'D'
        ELSE 'F'
    END;

    RETURN final_letter;
END$$
DELIMITER ;
