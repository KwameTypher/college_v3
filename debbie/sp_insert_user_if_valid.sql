DELIMITER $$

CREATE OR REPLACE PROCEDURE sp_insert_user_if_valid(
  IN  p_first_name    VARCHAR(100),
  IN  p_last_name     VARCHAR(100),
  IN  p_date_of_birth DATE,
  IN  p_gender        CHAR(1),
  IN  p_audit_userid  INT,
  OUT p_user_id       INT   -- success path sets this; error path leaves it NULL
)
BEGIN
  DECLARE v_error_msg VARCHAR(255); 
  DECLARE v_sqlstate CHAR(5);
  DECLARE v_errno INT;
  DECLARE v_num_errors INT DEFAULT 0; -- number of data validation errors

  -- Default OUT
  SET p_user_id = NULL;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    
    GET DIAGNOSTICS CONDITION 1  -- the most recent error that triggered your handler
      v_sqlstate = RETURNED_SQLSTATE,
      v_errno    = MYSQL_ERRNO,
      v_error_msg      = MESSAGE_TEXT;
      
	  SET v_error_msg = LEFT(CONCAT_WS('',
		  'Proc failed [', IFNULL(v_sqlstate,'HY000'), '/',
		  IFNULL(v_errno,0), ']: ',
		  IFNULL(v_error_msg,'(no message)')
		), 512);  -- using LEFT to make sure we don't exceed the lenght of an error message
        
    ROLLBACK;
    
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
  END;
  
  START TRANSACTION;  

  -- Temp table to collect validation messages
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_user_field_errors (
    field_name    VARCHAR(64),
    error_message VARCHAR(255)
  ) ENGINE=MEMORY;

  TRUNCATE TABLE tmp_user_field_errors;

  -- Call your UDF validators (each returns NULL if valid, else error text)
  SET v_error_msg = f_validate_first_name(p_first_name);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_user_field_errors VALUES ('first_name', v_error_msg);
  END IF;

  SET v_error_msg = f_validate_last_name(p_last_name);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_user_field_errors VALUES ('last_name', v_error_msg);
  END IF;

  SET v_error_msg = f_validate_dob(p_date_of_birth);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_user_field_errors VALUES ('date_of_birth', v_error_msg);
  END IF;

  SET v_error_msg = f_validate_gender(p_gender);
  IF v_error_msg IS NOT NULL THEN
    INSERT INTO tmp_user_field_errors VALUES ('gender', v_error_msg);
  END IF;

  -- Any validation errors?
  SELECT COUNT(*) INTO v_num_errors FROM tmp_user_field_errors;

  IF v_num_errors > 0 THEN
    SELECT field_name, error_message FROM tmp_user_field_errors;
    ROLLBACK;
  ELSE
	INSERT INTO `user`(first_name, last_name, date_of_birth, gender, audit_userid)
	VALUES (p_first_name, p_last_name, p_date_of_birth, p_gender, p_audit_userid);

	SET p_user_id = LAST_INSERT_ID();
	COMMIT;  
  END IF;

END$$

DELIMITER ;
