DROP PROCEDURE IF EXISTS sp_create_section;
DELIMITER $$
CREATE PROCEDURE sp_create_section(
    IN p_semester_id INT,
    IN p_course_id INT,
    IN p_instructor_id INT,
    IN p_dow VARCHAR(7),
    IN p_start_time TIME,
    IN p_end_time TIME,
    IN p_created_userid INT,
    IN p_room_ids VARCHAR(9), -- Comma separated list
    OUT p_section_id INT
)
BEGIN
	DECLARE v_room_id INT;
	DECLARE v_remaining TEXT DEFAULT p_room_ids;
	DECLARE v_next_comma INT;
    
    -- Variables for error handling
    DECLARE v_error_msg VARCHAR(255);
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errnum INT;
    DECLARE v_num_errors INT DEFAULT 0;

    -- Declare the error handler
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN     
        GET DIAGNOSTICS CONDITION 1 -- The most recent error that triggered the handler
        v_sqlstate = RETURNED_SQLSTATE,
        v_errnum = MYSQL_ERRNO,
        v_error_msg = MESSAGE_TEXT;
			
		SET v_error_msg = LEFT(CONCAT_WS('',
		  'Proc failed [', IFNULL(v_sqlstate,'HY000'), '/',
		  IFNULL(v_errnum,0), ']: ',
		  IFNULL(v_error_msg,'(no message)')
		), 512);  -- using LEFT to make sure we don't exceed the lenght of an error message
        ROLLBACK;
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END;
    -- End error handler
	
	START TRANSACTION;
	
    -- Set a default out
    SET p_section_id = NULL;
    
    -- Step 1: Validate foreign keys
    IF NOT EXISTS (SELECT 1 FROM semester WHERE id = p_semester_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid semester_id';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM course WHERE id = p_course_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid course_id';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM employee WHERE id = p_instructor_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid instructor_id';
    END IF;

    -- Step 2: Insert the new section
    INSERT INTO section (
        semester_id,
        course_id,
        instructor_id,
        dow,
        start_time,
        end_time,
        created_userid,
        updated_userid
    )
    VALUES (
        p_semester_id,
        p_course_id,
        p_instructor_id,
        p_dow,
        p_start_time,
        p_end_time,
        p_created_userid,
        p_created_userid
    );

    SET p_section_id = LAST_INSERT_ID();

    -- Step 3: Handle optional room assignments
    IF p_room_ids IS NOT NULL AND p_room_ids <> '' THEN
    
		-- Start loop to assign every room
        rooms_loop: LOOP
            SET v_next_comma = LOCATE(',', v_remaining);
            
			-- Get the first id listed or the only id listed
            IF v_next_comma > 0 THEN
                SET v_room_id = CAST(SUBSTRING(v_remaining, 1, v_next_comma - 1) AS UNSIGNED);
                SET v_remaining = SUBSTRING(v_remaining, v_next_comma + 1);
            ELSE
                SET v_room_id = CAST(v_remaining AS UNSIGNED);
                SET v_remaining = '';
            END IF;

            -- Verify room exists
            IF NOT EXISTS (SELECT 1 FROM room WHERE id = v_room_id) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'One or more room_ids are invalid';
            END IF;

			-- Verify the room is free
            IF (SELECT f_is_room_free(v_room_id, p_start_time, p_end_time, p_dow)) = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is already booked during specified time';
            END IF;

            -- Insert into section_room
            INSERT INTO section_room (room_id, section_id, created_userid, updated_userid)
            VALUES (v_room_id, p_section_id, p_created_userid, p_created_userid);

			-- Check if the loop should continue
            IF v_remaining = '' THEN
                LEAVE rooms_loop;
            END IF;
        END LOOP;
    END IF;

	COMMIT; -- Commit the changes
    
    -- Step 4: Return the new section ID
    SELECT p_section_id AS section_id;
END$$

DELIMITER ;
