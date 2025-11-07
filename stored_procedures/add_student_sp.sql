-- DROP PROCEDURE IF EXISTS AddStudentRecord;
DELIMITER //

CREATE PROCEDURE AddStudentRecord(
    IN first_name_param        VARCHAR(100),
    IN last_name_param         VARCHAR(100),
    IN dob_param               DATE,
    IN address_param           VARCHAR(255),
    IN email_param             VARCHAR(150),
    IN phone_number_param      VARCHAR(20),
    IN ssn_param               INT,
    IN university_id_param     INT,
    IN created_userid_param    INT,
    IN updated_userid_param    INT,
    IN admission_date_param    DATE,
    IN gpa_param               DECIMAL(3,2),
    IN student_status_param    VARCHAR(50),
    IN department_id_param     INT,
    OUT new_user_id_param      INT,
    OUT new_student_id_param   INT,
    OUT status_param           VARCHAR(255)
)

process: 
    BEGIN
    DECLARE valid_status_id INT;
    DECLARE exists_count INT DEFAULT 0;

    -- On any SQL error, roll back and set the outputs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET status_param = 'Error occurred while adding new student.';
        SET new_user_id_param = NULL;
        SET new_student_id_param = NULL;
    END;


    START TRANSACTION;

    -- Get the status_id from the input status name
    SELECT s.id
      INTO valid_status_id
      FROM af25enoca1_college_v3.`status` s
     WHERE LOWER(s.label) = LOWER(student_status_param)
     LIMIT 1;

    IF valid_status_id IS NULL THEN
        SET status_param = CONCAT('Invalid student status: ', student_status_param);
        ROLLBACK;
        LEAVE process;
    END IF;


    -- Check if the department exists
    SELECT COUNT(*) INTO exists_count
      FROM af25enoca1_college_v3.department d
     WHERE d.id = department_id_param;
    IF exists_count = 0 THEN
        SET status_param = CONCAT('Invalid department_id: ', department_id_param);
        ROLLBACK;
        LEAVE process;
    END IF;


    -- Uniqueness checks for email, ssn and university_id
    SELECT COUNT(*) INTO exists_count
      FROM af25enoca1_college_v3.`user` u
     WHERE u.email = email_param;
    IF exists_count > 0 THEN
        SET status_param = 'Email already exists.';
        ROLLBACK;
        LEAVE process;
    END IF;

    IF ssn_param IS NOT NULL THEN
        SELECT COUNT(*) INTO exists_count
          FROM af25enoca1_college_v3.`user` u
         WHERE u.ssn = ssn_param;
        IF exists_count > 0 THEN
            SET status_param = 'SSN already exists.';
            ROLLBACK;
            LEAVE process;
        END IF;
    END IF;

    IF university_id_param IS NOT NULL THEN
        SELECT COUNT(*) INTO exists_count
          FROM af25enoca1_college_v3.`user` u
         WHERE u.university_id = university_id_param;
        IF exists_count > 0 THEN
            SET status_param = 'University ID already exists.';
            ROLLBACK;
            LEAVE process;
        END IF;
    END IF;


    -- Insert into the user table
    INSERT INTO af25enoca1_college_v3.`user`
        (first_name, last_name, dob, address, email, phone_number, ssn, university_id, created_userid, updated_userid)
    VALUES
        (first_name_param, last_name_param, dob_param, address_param, email_param, phone_number_param,
         ssn_param, university_id_param, created_userid_param, updated_userid_param);

    SET new_user_id_param = LAST_INSERT_ID();

    -- Insert into student (note: use status_id instead of status label)
    INSERT INTO af25enoca1_college_v3.student
        (user_id, status, department_id, admission_date, gpa, created_userid, updated_userid)
    VALUES
        (new_user_id_param, valid_status_id, department_id_param, admission_date_param, gpa_param,
         created_userid_param, updated_userid_param);

    SET new_student_id_param = LAST_INSERT_ID();

    COMMIT;
    SET status_param = 'New student added successfully.';


    -- Display the new ID and status
    SELECT 
        new_user_id_param  AS user_id,
        new_student_id_param AS student_id,
        status_param       AS status_message;
END//

DELIMITER ;
