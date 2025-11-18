/*
This stored procedure will say 4 rows affected when completing successfully for the following reasons:
(1) create temp table
(2) truncate temp table
(3) insert user record
(4) insert student record

EXAMPLE OF TESTING THIS STORED PROCEDURE
========================================
CALL sp_insert_student_if_valid(
	'Debbie',
	'Johnson',
	'1998-12-13',
	'F', 
	1, 
	@new_student_id  -- will store the new student id or NULL if an error occurs
);

After running this stored procedure, you can run the following queries:
===========================================================================
SELECT @new_user_id; 					-- see the newly created student id 
SELECT * FROM tmp_student_field_errors;  -- to see any data validation errors
*/

DELIMITER $$

CREATE OR REPLACE PROCEDURE sp_insert_student_if_valid(
  IN  p_first_name    VARCHAR(255),
  IN  p_last_name     VARCHAR(255),
  IN  p_date_of_birth VARCHAR(255),
  IN  p_gender        CHAR(1),
  IN  p_audit_userid  INT,
  OUT p_student_id    INT   -- success path sets this; error path leaves it NULL
)
BEGIN
  DECLARE v_error_msg VARCHAR(255); 
  DECLARE v_sqlstate CHAR(5);
  DECLARE v_errno INT;
  DECLARE v_num_errors INT DEFAULT 0; -- number of data validation errors
  
  DECLARE v_user_exists INT DEFAULT 0; 
  DECLARE v_user_id INT DEFAULT 0;

  -- Default OUT
  SET p_student_id = NULL;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    
    GET DIAGNOSTICS CONDITION 1  -- the most recent error that triggered your handler
      v_sqlstate 	= RETURNED_SQLSTATE,
      v_errno    	= MYSQL_ERRNO,
      v_error_msg	= MESSAGE_TEXT;
      
	  SET v_error_msg = LEFT(CONCAT_WS('',
		  'Proc failed [', IFNULL(v_sqlstate, 'HY000'), '/', -- use the generic HY000 state if the sql state is NULL
		  IFNULL(v_errno, 0), ']: ',
		  IFNULL(v_error_msg, '(no message)')
		), 512);  -- using LEFT to make sure we don't exceed the lenght of an error message
        
    ROLLBACK;
    
    SIGNAL SQLSTATE '40000' SET MESSAGE_TEXT = v_error_msg;  -- 40000 stands for transaction rollback
  END;
  
  START TRANSACTION;  

  -- Temp table to collect validation messages
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_student_field_errors (
    field_name    VARCHAR(64),
    error_message VARCHAR(255)
  ) ENGINE=MEMORY;

  TRUNCATE TABLE tmp_student_field_errors;

  -- Call your UDF validators (each returns NULL if valid, else error text)
  SET v_error_msg = f_validate_first_name(p_first_name);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_student_field_errors VALUES ('first_name', v_error_msg);
  END IF;

  SET v_error_msg = f_validate_last_name(p_last_name);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_student_field_errors VALUES ('last_name', v_error_msg);
  END IF;

  SET v_error_msg = f_validate_date_of_birth(p_date_of_birth);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_student_field_errors VALUES ('date_of_birth', v_error_msg);
  END IF;

  SET v_error_msg = f_validate_gender(p_gender);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_student_field_errors VALUES ('gender', v_error_msg);
  END IF;

  -- Any validation errors?
  SELECT COUNT(*) INTO v_num_errors FROM tmp_student_field_errors;

  IF v_num_errors > 0 THEN
    SELECT field_name, error_message FROM tmp_student_field_errors;
    SIGNAL SQLSTATE '22000'       -- generic "bad data"
	   SET MYSQL_ERRNO  = 1366,   -- incorrect value for column
		   MESSAGE_TEXT = "Invalid User Data";
  END IF;
  
  SELECT COUNT(*) INTO v_user_exists
  FROM user
  WHERE first_name = p_first_name 
	AND last_name = p_last_name 
    AND date_of_birth = p_date_of_birth 
    AND gender = p_gender;
  
  IF v_user_exists > 0 THEN 
    SIGNAL SQLSTATE '22000'       -- generic "bad data"
	   SET MYSQL_ERRNO  = 1062,   -- duplicate entry
		   MESSAGE_TEXT = "User Already Exists";
  END IF;
  
  INSERT INTO user (first_name, last_name, date_of_birth, gender, audit_userid)
  VALUES (p_first_name, p_last_name, p_date_of_birth, p_gender, p_audit_userid);

  SET v_user_id = LAST_INSERT_ID();
  
  INSERT INTO student (user_id, student_status_id, audit_userid) 
  VALUES (v_user_id, 1, p_audit_userid);  -- 1=enrolled
  
  SET p_student_id = LAST_INSERT_ID();
  
  COMMIT;  
  
END$$

DELIMITER ;
