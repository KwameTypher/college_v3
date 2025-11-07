DELIMITER $$

CREATE OR REPLACE FUNCTION f_validate_first_name(p_first VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC -- the function always returns the same result given the same input parameters
BEGIN
  IF p_first IS NULL OR p_first = '' THEN
    RETURN 'First name is required';
  ELSEIF p_first NOT REGEXP '^[A-Za-z][A-Za-z \\-\\'']{0,99}$' THEN
    RETURN 'First name may contain only letters, spaces, hyphens, or apostrophes';
  END IF;
  RETURN NULL;
END$$

CREATE OR REPLACE FUNCTION f_validate_last_name(p_last VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC -- the function always returns the same result given the same input parameters
BEGIN
  IF p_last IS NULL OR p_last = '' THEN
    RETURN 'Last name is required';
  ELSEIF p_last NOT REGEXP '^[A-Za-z][A-Za-z \\-\\'']{0,99}$' THEN
    RETURN 'Last name may contain only letters, spaces, hyphens, or apostrophes';
  END IF;
  RETURN NULL;
END$$

CREATE OR REPLACE FUNCTION f_validate_dob(p_dob DATE)
RETURNS VARCHAR(255)
DETERMINISTIC -- the function always returns the same result given the same input parameters
BEGIN
  IF p_dob IS NULL THEN
    RETURN 'Date of birth is required';
  ELSEIF p_dob > CURDATE() THEN
    RETURN 'Date of birth cannot be in the future';
  ELSEIF TIMESTAMPDIFF(YEAR, p_dob, CURDATE()) < 14 THEN
    RETURN 'User must be at least 14 years old';
  END IF;
  RETURN NULL;
END$$

CREATE OR REPLACE FUNCTION f_validate_gender(p_gender CHAR(1))
RETURNS VARCHAR(255)
DETERMINISTIC -- the function always returns the same result given the same input parameters
BEGIN
  IF p_gender IS NULL OR UPPER(p_gender) NOT IN ('M','F','X') THEN
    RETURN 'Gender must be one of M, F, or X';
  END IF;
  RETURN NULL;
END$$

CREATE OR REPLACE FUNCTION f_validate_email(p_email VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC -- the function always returns the same result given the same input parameters
BEGIN
  IF p_email IS NULL OR p_email = '' THEN
    RETURN 'Email address is required';
  ELSEIF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
    RETURN 'Email address is invalid';
  END IF;
  RETURN NULL;
END$$

DELIMITER ;