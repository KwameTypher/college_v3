DELIMITER //
DROP PROCEDURE IF EXISTS sp_enroll_student;

CREATE PROCEDURE sp_enroll_student(
    IN student_id_param INT,
    IN semester_name_param VARCHAR(50),
    IN year_param INT,
    IN course_code_param VARCHAR(50),
    IN created_userid_param INT,
    IN updated_userid_param INT,
    OUT enrollment_id_param INT,
    OUT valid_section_id_param INT,
    OUT status_param VARCHAR(255)
)
BEGIN
    DECLARE valid_semester_id INT;
    DECLARE valid_course_id INT;
    DECLARE available_seats INT;

    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errno INT;
    DECLARE v_error_msg TEXT;

    -- Error handler for unexpected SQL exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE,
            v_errno    = MYSQL_ERRNO,
            v_error_msg = MESSAGE_TEXT;

        SET v_error_msg = LEFT(CONCAT_WS('',
            'Procedure EnrollStudentInSection failed [', IFNULL(v_sqlstate,'HY000'), '/',
            IFNULL(v_errno,0), ']: ',
            IFNULL(v_error_msg,'(no message)')
        ), 512);

        ROLLBACK;
        SET enrollment_id_param = NULL;
        SET valid_section_id_param = NULL;
        SET status_param = v_error_msg;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END;

    SET enrollment_id_param = NULL;
    SET valid_section_id_param = NULL;
    SET status_param = NULL;

    START TRANSACTION;

    -- 1. Check if student is active
    IF NOT EXISTS (
        SELECT 1
        FROM af25enoca1_college_v3.student stu
        JOIN af25enoca1_college_v3.status s ON stu.status = s.id
        WHERE stu.id = student_id_param AND LOWER(s.label) = 'active'
    ) THEN
        SET status_param = 'Student is not active and cannot be enrolled.';
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- 2. Get semester_id
    SELECT sem.id INTO valid_semester_id
    FROM af25enoca1_college_v3.semester sem
    WHERE LOWER(sem.term) = LOWER(semester_name_param) AND sem.year = year_param
    LIMIT 1;

    IF valid_semester_id IS NULL THEN
        SET status_param = CONCAT('Invalid semester: ', semester_name_param, ' and year: ', year_param);
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- 3. Get course_id
    SELECT course.id INTO valid_course_id
    FROM af25enoca1_college_v3.course course
    WHERE course.name LIKE CONCAT('%', course_code_param, '%')
    LIMIT 1;

    IF valid_course_id IS NULL THEN
        SET status_param = CONCAT('Invalid course code: ', course_code_param);
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- 4. Get section_id
    SELECT sec.id INTO valid_section_id_param
    FROM af25enoca1_college_v3.section sec
    WHERE sec.course_id = valid_course_id AND sec.semester_id = valid_semester_id
    LIMIT 1;

    IF valid_section_id_param IS NULL THEN
        SET status_param = CONCAT('No section found for course ', course_code_param, ' in ', semester_name_param, ' ', year_param);
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- 5. Check if already enrolled
    IF EXISTS (
        SELECT 1
        FROM af25enoca1_college_v3.enrollment e
        WHERE e.student_id = student_id_param AND e.section_id = valid_section_id_param
    ) THEN
        SET status_param = 'Student is already enrolled in this section.';
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- 6. Check available seats
    SET available_seats = af25enoca1_college_v3.get_available_seats(valid_section_id_param);
    IF available_seats <= 0 THEN
        SET status_param = 'No available seats in this section.';
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    -- 7. Insert enrollment
    INSERT INTO af25enoca1_college_v3.enrollment (
        student_id,
        section_id,
        created_userid,
        updated_userid,
        created
    ) VALUES (
        student_id_param,
        valid_section_id_param,
        created_userid_param,
        updated_userid_param,
        NOW()
    );

    SET enrollment_id_param = LAST_INSERT_ID();

    COMMIT;
    SET status_param = 'Enrollment successful.';

    -- Return final info
    SELECT enrollment_id_param AS new_enrollment_id, valid_section_id_param AS section_id, status_param AS status_message;

proc_end: END;
//
DELIMITER ;
