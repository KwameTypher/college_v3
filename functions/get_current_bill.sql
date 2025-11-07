-- Function to get the bill of a student in a given semester and year given their student_id


DELIMITER //
CREATE FUNCTION get_bill(student_id INT, semester VARCHAR(10), year INT)
RETURNS DECIMAL(5,2)