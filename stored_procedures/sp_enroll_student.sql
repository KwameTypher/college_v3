DELIMITER //
-- DROP PROCEDURE IF EXISTS sp_enroll_student;

CREATE PROCEDURE sp_enroll_student(
    IN p_student_id INT,
    IN p_semester_name VARCHAR(50),
    IN p_year INT,
    IN p_course_code VARCHAR(50),
    IN p_created_userid INT,
    IN p_updated_userid INT,
    OUT p_enrollment_id INT,
    OUT p_section_id INT,
    OUT p_status VARCHAR(255)
)
BEGIN
    DECLARE v_semester_id INT;
    DECLARE v_course_id INT;
    DECLARE v_available_seats INT;
    DECLARE v_num_errors INT DEFAULT 0;

    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errno INT;
    DECLARE v_error_msg TEXT;
    DECLARE v_text TEXT;

    -- Error handler for unexpected SQL exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE,
            v_errno    = MYSQL_ERRNO,
            v_error_msg = MESSAGE_TEXT;

        SET v_error_msg = LEFT(CONCAT_WS('',
            'Procedure sp_enroll_student failed [', IFNULL(v_sqlstate,'HY000'), '/',
            IFNULL(v_errno,0), ']: ',
            IFNULL(v_error_msg,'(no message)')
        ), 512);

        ROLLBACK;
        SET p_enrollment_id = NULL;
        SET p_section_id = NULL;
        SET p_status = v_error_msg;
        SELECT p_status AS status_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END;

    SET p_enrollment_id = NULL;
    SET p_section_id = NULL;
    SET p_status = NULL;

    START TRANSACTION;

    -- Create temp table for validation errors
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_enrollment_errors (
        field_name    VARCHAR(64),
        error_message VARCHAR(255)
    ) ENGINE=MEMORY;

    TRUNCATE TABLE tmp_enrollment_errors;

    -- 1. Check if student is active
    IF NOT EXISTS (
        SELECT 1
        FROM af25enoca1_college_v3.student stu
        JOIN af25enoca1_college_v3.status s ON stu.status = s.id
        WHERE stu.id = p_student_id AND LOWER(s.label) = 'active'
    ) THEN
        INSERT INTO tmp_enrollment_errors VALUES ('student_status', 'Student is not active and cannot be enrolled.');
    END IF;

    -- 2. Get semester_id
SELECT 
    sem.id
INTO v_semester_id FROM
    af25enoca1_college_v3.semester sem
WHERE
    LOWER(sem.term) = LOWER(p_semester_name)
        AND sem.year = p_year
LIMIT 1;

    IF v_semester_id IS NULL THEN
        INSERT INTO tmp_enrollment_errors VALUES ('semester', CONCAT('Invalid semester: ', p_semester_name, ' and year: ', p_year));
    END IF;

    -- 3. Get course_id
SELECT 
    course.id
INTO v_course_id FROM
    af25enoca1_college_v3.course course
WHERE
    course.name LIKE CONCAT('%', p_course_code, '%')
LIMIT 1;

    IF v_course_id IS NULL THEN
        INSERT INTO tmp_enrollment_errors VALUES ('course_code', CONCAT('Invalid course code: ', p_course_code));
    END IF;

    -- 4. Get section_id
SELECT 
    sec.id
INTO p_section_id FROM
    af25enoca1_college_v3.section sec
WHERE
    sec.course_id = v_course_id
        AND sec.semester_id = v_semester_id
LIMIT 1;

    IF p_section_id IS NULL THEN
        INSERT INTO tmp_enrollment_errors VALUES ('section', CONCAT('No section found for course ', p_course_code, ' in ', p_semester_name, ' ', p_year));
    END IF;

    -- 5. Check if already enrolled
    IF EXISTS (
        SELECT 1
        FROM af25enoca1_college_v3.enrollment e
        WHERE e.student_id = p_student_id AND e.section_id = p_section_id
    ) THEN
        INSERT INTO tmp_enrollment_errors VALUES ('enrollment_duplicate', 'Student is already enrolled in this section.');
    END IF;

    -- 6. Check available seats
    SET v_available_seats = af25enoca1_college_v3.f_get_available_seats(p_section_id);
    IF v_available_seats <= 0 THEN
        INSERT INTO tmp_enrollment_errors VALUES ('available_seats', 'No available seats in this section.');
    END IF;

    -- Check if any errors exist
    SELECT COUNT(*) INTO v_num_errors FROM tmp_enrollment_errors;

    IF v_num_errors > 0 THEN
        -- Return all the field-specific error messages at once
        SELECT field_name, error_message FROM tmp_enrollment_errors;
        ROLLBACK;
    ELSE

    -- 7. Insert enrollment
    INSERT INTO af25enoca1_college_v3.enrollment (
        student_id,
        section_id,
        created_userid,
        updated_userid,
        created
    ) VALUES (
        p_student_id,
        p_section_id,
        p_created_userid,
        p_updated_userid,
        NOW()
    );

    SET p_enrollment_id = LAST_INSERT_ID();

    COMMIT;
    SET p_status = 'Enrollment successful.';

    -- Return final info
SELECT 
    p_enrollment_id AS new_enrollment_id,
    p_section_id AS section_id,
    p_status AS status_message;

    END IF;
END;
//
DELIMITER ;
