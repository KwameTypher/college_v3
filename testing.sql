-- Testing enroll student stored procedure
-- Good case: Valid enrollment
CALL af25enoca1_college_v3.sp_enroll_student(
    283,                -- student_id_param
    'Fall',             -- semester_name_param
    2024,               -- year_param
    'CS 129',            -- course_code_param
    1,                  -- created_userid_param
    1,                  -- updated_userid_param
    @enrollment_id,     -- OUT enrollment_id_param
    @section_id,		-- OUT valid_section_id
    @status_msg         -- OUT status_param
);

-- Error testing: invalid semester, invalid course code, year
CALL af25enoca1_college_v3.sp_enroll_student(
    279,                -- student_id_param
    'Fall',             -- semester_name_param
    202,               -- year_param
    'CS',            -- course_code_param
    1,                  -- created_userid_param
    1,                  -- updated_userid_param
    @enrollment_id,     -- OUT enrollment_id_param
    @section_id,		-- OUT valid_section_id
    @status_msg         -- OUT status_param
);







-- Testing add student stored procedure

CALL af25enoca1_college_V3.sp_add_student(
    'Liam',
    'Rodriguez',
    '2002-11-03',
    '58 Oakwood Ave, Norfolk, NE',
    'liam.rodriguez@wildcats.edu',
    '402-555-1823',
    100000146,
    900000224,
    1,
    1,
    '2020-08-17',
    3.45,
    'Active',
    12,
    @new_user_id,
    @new_student_id,
    @status_message
);



CALL sp_add_student(
    'Sophia',
    'Patel',
    '2004-02-12',
    '915 Sunset Blvd, Wayne, NE',
    'sophia.patel@wildcats.edu',
    '402-555-9901',
    100000147,
    900000225,
    1,
    1,
    '2022-08-21',
    3.91,
    'Active',
    4,
    @new_user_id,
    @new_student_id,
    @status_message
);
SELECT @new_user_id AS user_id, @new_student_id AS student_id, @status_message AS status_message;

CALL sp_add_student(
    'Ethan',
    'Nguyen',
    '2001-09-10',
    '302 Hilltop Dr, Omaha, NE',
    'ethan.nguyen@wildcats.edu',
    '402-555-3129',
    100000148,
    900000226,
    1,
    1,
    '2019-08-19',
    3.25,
    'Active',
    7,
    @new_user_id,
    @new_student_id,
    @status_message
);
SELECT @new_user_id AS user_id, @new_student_id AS student_id, @status_message AS status_message;


CALL sp_add_student(
    'Olivia',
    'Johnson',
    '2002-06-15',
    '210 Pine Street, Wayne, NE',
    'olivia.johnson@wildcats.edu',
    '402-555-4402',
    100000149,
    900000227,
    1,
    1,
    '2020-08-24',
    3.88,
    'Active',
    1,
    @new_user_id,
    @new_student_id,
    @status_message
);
SELECT @new_user_id AS user_id, @new_student_id AS student_id, @status_message AS status_message;


CALL sp_add_student(
    'Mason',
    'Lee',
    '2003-01-27',
    '100 Cedar Lane, Kearney, NE',
    'mason.lee@wildcats.edu',
    '402-555-7721',
    100000150,
    900000228,
    1,
    1,
    '2021-08-20',
    3.57,
    'Active',
    3,
    @new_user_id,
    @new_student_id,
    @status_message
);
SELECT @new_user_id AS user_id, @new_student_id AS student_id, @status_message AS status_message;

