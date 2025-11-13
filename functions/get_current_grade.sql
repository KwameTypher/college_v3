-- Function to get the current grade of a student in a specific section
DROP FUNCTION IF EXISTS get_current_grade;

DELIMITER $$
CREATE FUNCTION get_current_grade(student_id INT, section_id INT)
RETURNS VARCHAR(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE enrollment_id INT;
    DECLARE current_grade VARCHAR(1);

    -- Get the enrollment id
    SELECT e.id
      INTO enrollment_id
    FROM af25enoca1_college_v3.`enrollment` e
    WHERE e.student_id = student_id
      AND e.section_id = section_id
    LIMIT 1;

    -- If no enrollment exists, return NULL
    IF enrollment_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Retrieve the current grade from the grades table
    SELECT g.letter
    INTO current_grade
    FROM af25enoca1_college_v3.`grade` g
    WHERE g.enrollment_id = enrollment_id
    LIMIT 1;

    RETURN current_grade;
END$$