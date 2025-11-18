DELIMITER $$

CREATE FUNCTION f_get_remaining_credits(p_student_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_required_credits INT DEFAULT 120;
    DECLARE v_total_classes INT DEFAULT 0;
	DECLARE v_completed_credits INT DEFAULT 0;
    
    -- Get the amount of classes the student has completed
	SELECT COUNT(DISTINCT section_id) AS total_sections
    INTO v_total_classes
	FROM enrollment
	WHERE student_id = p_student_id;
    
    -- Multiply the amount of classes to get the credits
	SET v_completed_credits = v_total_classes * 3;
	
    -- Calculate the amount of credits left
    SET v_required_credits = v_required_credits - v_completed_credits;
    
	RETURN GREATEST(v_required_credits, 0);
END$$

DELIMITER ;
