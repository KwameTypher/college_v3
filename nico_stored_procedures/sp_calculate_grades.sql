
DROP PROCEDURE IF EXISTS sp_calculate_grades;
DELIMITER $$
CREATE PROCEDURE sp_calculate_grades(
	IN p_section_id INT
)
BEGIN
	
    -- Declare any necessary variables
	DECLARE v_student_id INT;
    DECLARE v_enrollment_id INT;
    DECLARE v_letter_grade VARCHAR(255);
	DECLARE v_error_msg VARCHAR(255);
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errnum INT;
    DECLARE v_num_errors INT DEFAULT 0;
    DECLARE v_end_loop BOOL DEFAULT FALSE;
    
	DECLARE cur CURSOR FOR 
		SELECT s.id FROM student s 
		JOIN enrollment e ON s.id = e.student_id
		JOIN status st ON st.id = s.status
		WHERE e.section_id = p_section_id AND s.status in (1, 2);
	
    -- Handler for when the loop should finish
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_end_loop = TRUE;
	
	-- Declare an error handler
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN     
        GET DIAGNOSTICS CONDITION 1 -- The most recent error that triggered the handler
        v_sqlstate = RETURNED_SQLSTATE,
        v_errnum = MYSQL_ERRNO,
        v_error_msg = MESSAGE_TEXT;
			
		SET v_error_msg = LEFT(CONCAT_WS('',
		  'Proc failed [', IFNULL(v_sqlstate,'HY000'), '/',
		  IFNULL(v_errnum,0), ']: ',
		  IFNULL(v_error_msg,'(no message)'),
		  ' | Student ID: ', IFNULL(v_student_id, 'N/A')
		), 512);  -- using LEFT to make sure we don't exceed the lenght of an error message
        ROLLBACK;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END;


    
	START TRANSACTION;
	
    -- Check if the section exists
    IF NOT EXISTS (SELECT 1 FROM section WHERE id = p_section_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid section_id';
    END IF;
    
    -- Get all (active) students in that section
    -- Declares a cursor that points to the specific rows
	

	-- Open the cursor
	OPEN cur;
    
    -- Loop through the students
	grade_updates_loop: LOOP
		FETCH cur INTO v_student_id; -- Get each row individually
		IF v_end_loop THEN
		  LEAVE grade_updates_loop;
		END IF;
        
		SELECT id
		INTO v_enrollment_id 
		FROM enrollment
		WHERE student_id = v_student_id AND section_id = p_section_id
		LIMIT 1;
	
		-- Calculate each student's grade 
		SELECT f_get_current_grade(v_student_id, p_section_id) INTO v_letter_grade;
	
		IF v_letter_grade IS NOT NULL THEN
			IF EXISTS (SELECT 1 FROM grade WHERE enrollment_id = v_enrollment_id AND type = 7) THEN
				UPDATE grade
				SET letter = v_letter_grade, updated_userid = 1
				WHERE enrollment_id = v_enrollment_id AND type = 7;
			ELSE
				INSERT INTO grade (letter, enrollment_id, type, created_userid, updated_userid)
				VALUES (v_letter_grade, v_enrollment_id, 7, 1, 1);
			END IF;
        END IF;
	END LOOP;
    
    CLOSE cur;
    COMMIT;
END$$

DELIMITER ;