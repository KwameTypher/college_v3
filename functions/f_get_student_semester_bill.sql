-- Function to calculate the current semester bill for a student
DROP FUNCTION IF EXISTS af25enoca1_college_v3.get_student_semester_bill;

DELIMITER $$

DROP FUNCTION IF EXISTS f_get_student_semester_bill$$

CREATE FUNCTION f_get_student_semester_bill(
    p_student_id INT,
    p_term VARCHAR(50),
    p_year INT,
    p_per_credit_fee DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_semester_id INT;
    DECLARE v_total_credits INT DEFAULT 0;
    DECLARE v_total_bill DECIMAL(10,2) DEFAULT 0;

    -- 1. Get the semester ID
    SELECT sem.id
    INTO v_semester_id
    FROM af25enoca1_college_v3.semester sem
    WHERE LOWER(sem.term) = LOWER(p_term)
      AND sem.year = p_year
    LIMIT 1;

    -- If semester not found, return 0
    IF v_semester_id IS NULL THEN
        RETURN 0;
    END IF;

    -- 2. Sum credits for all sections the student is enrolled in this semester
    SELECT SUM(LENGTH(sec.dow)) INTO v_total_credits
    FROM af25enoca1_college_v3.enrollment e
    JOIN af25enoca1_college_v3.section sec ON e.section_id = sec.id
    WHERE e.student_id = p_student_id
      AND sec.semester_id = v_semester_id;

    -- If student has no enrollments, return 0
    IF v_total_credits IS NULL THEN
        RETURN 0;
    END IF;

    -- 3. Calculate total bill
    SET v_total_bill = v_total_credits * p_per_credit_fee;

    RETURN v_total_bill;
END$$

DELIMITER ;
