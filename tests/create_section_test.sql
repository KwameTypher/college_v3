select * from section where id > 870;

-- Declare a variable to receive the OUT value
SET @new_section_id = 0;

-- Call the procedure
CALL create_section(
    1,               -- p_semester_id
    2,               -- p_course_id
	7,               -- p_instructor_id
    'R',           -- p_dow
    '01:00:00',      -- p_start_time
    '02:15:00',      -- p_end_time
    1,               -- p_created_userid
    '5,7',           -- p_room_ids
    @new_section_id  -- OUT p_section_id
);

-- Check the returned section_id
SELECT @new_section_id;