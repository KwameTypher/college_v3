DROP PROCEDURE IF EXISTS af25enoca1_college_v3.EnrollStudentInSection;
DELIMITER //

CREATE PROCEDURE af25enoca1_college_v3.EnrollStudentInSection(
    IN student_id_param INT,
    IN semester_name_param VARCHAR(50),
    IN year_param INT,
    IN course_code_param VARCHAR(50),
    IN created_userid_param INT,
    IN updated_userid_param INT,
    OUT enrollment_id_param INT,
    OUT valid_section_id INT,
    OUT status_param VARCHAR(255)
)

process:
    BEGIN
    DECLARE valid_semester_id INT;
    DECLARE valid_course_id INT;
    DECLARE valid_section_id INT;
    DECLARE available_seats INT;

    -- Rollback on any error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET status_param = 'Error occured while adding new enrollment record';
        SET enrollment_id_param = NULL;
    END;


    START TRANSACTION;

     -- check for student status (should be active)
    IF NOT EXISTS (
        SELECT 1
        FROM af25enoca1_college_v3.`student` stu
        JOIN af25enoca1_college_v3.`status` s ON stu.status = s.id
        WHERE stu.id = student_id_param AND LOWER(s.label) = 'active'
    ) THEN
        SET status_param = 'Student is not active and cannot be enrolled.';
        ROLLBACK;
        LEAVE process;
    END IF;


    -- Get the semester_id from the semester name and year inputs
SELECT 
    sem.id
INTO valid_semester_id FROM
    af25enoca1_college_v3.`semester` sem
WHERE
    LOWER(semester_name_param) = LOWER(sem.term)
        AND year_param = sem.year
LIMIT 1;

    IF valid_semester_id IS NULL THEN
        SET status_param = CONCAT('Invalid semester: ', semester_name_param, ' and year: ', year_param);
        ROLLBACK;
        LEAVE process;
    END IF;


    -- Get the course_id
SELECT 
    course.id
INTO valid_course_id FROM
    af25enoca1_college_v3.`course` course
WHERE course.name LIKE CONCAT('%', course_code_param, '%');

    IF valid_course_id IS NULL THEN
        SET status_param = CONCAT('Invalid course code: ', course_code_param);
        ROLLBACK;
        LEAVE process;
    END IF;


    -- Get the section_id
SELECT 
    sec.id
INTO valid_section_id FROM
    af25enoca1_college_v3.`section` sec
WHERE
    sec.course_id = valid_course_id
        AND sec.semester_id = valid_semester_id
LIMIT 1;

    IF valid_section_id IS NULL THEN
        SET status_param = CONCAT('No section found for course code: ', course_code_param, ' in semester: ', semester_name_param, ' and year: ', year_param);
        ROLLBACK;
        LEAVE process;
    END IF;


    -- check if not already enrolled
    IF EXISTS (
        SELECT 1
        FROM af25enoca1_college_v3.`enrollment` e
        WHERE e.student_id = student_id_param AND e.section_id = valid_section_id
    ) THEN
        SET status_param = 'Student is already enrolled in this section.';
        ROLLBACK;
        LEAVE process;
    END IF;


    -- check seat availability using a function: get_available_seats(sectionId INT)
    SET available_seats = af25enoca1_college_v3.get_available_seats(valid_section_id);
    IF available_seats <= 0 THEN
        SET status_param = 'No available seats in this section.';
        ROLLBACK;
        LEAVE process;
    END IF;

   

    -- Insert the enrollment record
    INSERT INTO af25enoca1_college_v3.enrollment (
        student_id,
        section_id,
        created_userid,
        updated_userid,
        created
    ) VALUES (
        student_id_param,
        valid_section_id,
        created_userid_param,
        updated_userid_param,
        NOW()
    );

    SET enrollment_id_param = LAST_INSERT_ID();
    
    COMMIT;
    SET status_param = 'Enrollment successful.';

    -- Display the new enrollment ID and status message
    SELECT enrollment_id_param AS new_enrollment_id, valid_section_id AS section_id, status_param AS status_message;

END//
DELIMITER ;


    