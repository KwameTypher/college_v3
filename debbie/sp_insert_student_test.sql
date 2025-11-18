-- Used to store the newly inserted user_id or NULL if an error occurs
SET @new_student_id = NULL;

-- How to test the stored procedure
CALL sp_insert_student_if_valid(
  'Debbie',
  'Johnson',
  '1971-02-27',
  'F',
  1,
  @new_student_id  -- will store the new user id or NULL if an error occurs
);

-- How to display the newly inserted user_id or NULL if an error occurs
SELECT @new_student_id;

-- How to display the data validation errors
-- SELECT * FROM tmp_student_field_errors;