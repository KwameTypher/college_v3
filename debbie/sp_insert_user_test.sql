SET @new_user_id = NULL;
CALL sp_insert_user_if_valid(
  'Bob',
  'Smith',
  '1998-02-12',
  'X',
  1,
  @new_user_id
);

SELECT @new_user_id;
-- SELECT * FROM tmp_user_field_errors;