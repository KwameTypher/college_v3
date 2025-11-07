-- Function to get the current grade of a student in a specific section
DELIMITER $$
CREATE FUNCTION get_current_grade(student_id INT, section_id INT)
RETURNS VARCHAR(1)
DETERMINISTIC
BEGIN
    DECLARE current_grade DECIMAL(5,2);

    -- DECLARE enrollment_id INT,

    -- -- Get the enrollment id
    -- SELECT e.id
    --   INTO enrolment_id
    -- FROM af25enoca1_college_v3.`enrollment` e
    -- WHERE e.student_id = student_id
    --   AND e.section_id = section_id
    -- LIMIT 1


    -- Retrieve the current grade from the grades table
    SELECT g.letter
    INTO current_grade
    FROM af25enoca1_college_v3.`grade` g
    WHERE g.enrolment_id = (
        SELECT e.id
        FROM af25enoca1_college_v3.`enrollment` e
        WHERE e.student_id = student_id
          AND e.section_id = section_id
        LIMIT 1
    )
    LIMIT 1;

    RETURN current_grade;
END$$