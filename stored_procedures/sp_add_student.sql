DELIMITER //
DROP PROCEDURE IF EXISTS sp_add_student;

CREATE PROCEDURE sp_add_student(
    IN  p_first_name        VARCHAR(100),
    IN  p_last_name         VARCHAR(100),
    IN  p_dob               DATE,
    IN  p_address           VARCHAR(255),
    IN  p_email             VARCHAR(150),
    IN  p_phone_number      VARCHAR(20),
    IN  p_ssn               INT,
    IN  p_university_id     INT,
    IN  p_created_userid    INT,
    IN  p_updated_userid    INT,
    IN  p_admission_date    DATE,
    IN  p_gpa               DECIMAL(3,2),
    IN  p_student_status    VARCHAR(50),
    IN  p_department_id     INT,
    OUT p_new_user_id       INT,
    OUT p_new_student_id    INT
)
BEGIN
    DECLARE v_valid_status_id INT;
    DECLARE v_exists_count INT DEFAULT 0;

    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errno INT;
    DECLARE v_error_msg TEXT;
    DECLARE text TEXT;
    DECLARE v_num_errors INT DEFAULT 0;


    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE,
            v_errno    = MYSQL_ERRNO,
            v_error_msg = MESSAGE_TEXT;

        SET v_error_msg = LEFT(CONCAT_WS('',
            'Procedure AddStudentRecord failed [', IFNULL(v_sqlstate,'HY000'), '/',
            IFNULL(v_errno,0), ']: ',
            IFNULL(v_error_msg,'(no message)')
        ), 512);

        ROLLBACK;
        SELECT v_error_msg AS status_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END;

    SET p_new_user_id = NULL;
    SET p_new_student_id = NULL;

    START TRANSACTION;

        -- 1. Create temp table for validation errors
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_user_field_errors (
        field_name    VARCHAR(64),
        error_message VARCHAR(255)
    ) ENGINE=MEMORY;

    TRUNCATE TABLE tmp_user_field_errors;

    -- 2. Run field validations (using UDFs that return NULL if valid, else message)
    SET v_error_msg = f_validate_first_name(p_first_name);
    IF v_error_msg IS NOT NULL THEN
        INSERT INTO tmp_user_field_errors VALUES ('first_name', v_error_msg);
    END IF;

    SET v_error_msg = f_validate_last_name(p_last_name);
    IF v_error_msg IS NOT NULL THEN
        INSERT INTO tmp_user_field_errors VALUES ('last_name', v_error_msg);
    END IF;

    SET v_error_msg = f_validate_dob(p_dob);
    IF v_error_msg IS NOT NULL THEN
        INSERT INTO tmp_user_field_errors VALUES ('date_of_birth', v_error_msg);
    END IF;

    -- 3. Check if any errors exist
    SELECT COUNT(*) INTO v_num_errors FROM tmp_user_field_errors;

    IF v_num_errors > 0 THEN
        -- Return all the field-specific messages at once
        SELECT field_name, error_message FROM tmp_user_field_errors;
        ROLLBACK;
    ELSE

        -- Additional logic validations
        SELECT s.id INTO v_valid_status_id
        FROM af25enoca1_college_v3.status s
        WHERE LOWER(s.label) = LOWER(p_student_status)
        LIMIT 1;

        IF v_valid_status_id IS NULL THEN
            SET text = CONCAT('Invalid student status: ', p_student_status);
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = text;
        END IF;

        SELECT COUNT(*) INTO v_exists_count
        FROM af25enoca1_college_v3.department d
        WHERE d.id = p_department_id;

        IF v_exists_count = 0 THEN
            SET text = CONCAT('Invalid department ID: ', p_department_id);
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = text;
        END IF;

        SELECT COUNT(*) INTO v_exists_count
        FROM af25enoca1_college_v3.`user` u
        WHERE u.email = p_email;

        IF v_exists_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Email already exists.';
        END IF;
        
        IF p_phone_number IS NOT NULL THEN
            SELECT COUNT(*) INTO v_exists_count
            FROM af25enoca1_college_v3.`user` u
            WHERE u.phone_number = p_phone_number;
            IF v_exists_count > 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Phone number already exists.';
            END IF;
        END IF;

        IF p_ssn IS NOT NULL THEN
            SELECT COUNT(*) INTO v_exists_count
            FROM af25enoca1_college_v3.`user` u
            WHERE u.ssn = p_ssn;
            IF v_exists_count > 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'SSN already exists.';
            END IF;
        END IF;

        IF p_university_id IS NOT NULL THEN
            SELECT COUNT(*) INTO v_exists_count
            FROM af25enoca1_college_v3.`user` u
            WHERE u.university_id = p_university_id;
            IF v_exists_count > 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'University ID already exists.';
            END IF;
        END IF;

        INSERT INTO af25enoca1_college_v3.`user` (
            first_name, last_name, dob, address, email, phone_number,
            ssn, university_id, created_userid, updated_userid
        ) VALUES (
            p_first_name, p_last_name, p_dob, p_address, p_email, p_phone_number,
            p_ssn, p_university_id, p_created_userid, p_updated_userid
        );

        SET p_new_user_id = LAST_INSERT_ID();

        INSERT INTO af25enoca1_college_v3.student (
            user_id, status, department_id, admission_date, gpa, created_userid, updated_userid
        ) VALUES (
            p_new_user_id, v_valid_status_id, p_department_id, p_admission_date, p_gpa,
            p_created_userid, p_updated_userid
        );

        SET p_new_student_id = LAST_INSERT_ID();

        COMMIT;
        
        SELECT p_new_user_id AS user_id, p_new_student_id AS student_id, 'Student record successfully added.' AS status_message;
END IF;
END;
//

DELIMITER ;
