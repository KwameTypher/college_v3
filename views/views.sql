-- Course offerings with enrollment count
CREATE OR REPLACE VIEW course_offerings AS
SELECT 
    c.name AS course_name,
    sem.term,
    sem.year,
    s.dow,
    CONCAT(s.start_time, ' - ', s.end_time) AS time,
    CONCAT(u.first_name, ' ', u.last_name) AS instructor_name,
    GROUP_CONCAT(DISTINCT r.name ORDER BY r.name SEPARATOR ', ') AS rooms,
    MIN(r.capacity) AS capacity,
    COUNT(DISTINCT e.student_id) AS total_enrolled,
    (MIN(r.capacity) - COUNT(DISTINCT e.student_id)) AS remaining_seats
FROM section s
JOIN course c 
    ON s.course_id = c.id
JOIN semester sem
    ON s.semester_id = sem.id
JOIN employee emp
    ON s.instructor_id = emp.id
JOIN user u 
    ON emp.user_id = u.id
JOIN section_room sr 
    ON s.id = sr.section_id
JOIN room r 
    ON sr.room_id = r.id
LEFT JOIN enrollment e 
    ON e.section_id = s.id
GROUP BY 
    s.id, c.name, sem.term, sem.year, s.dow, s.start_time, s.end_time, 
    u.first_name, u.last_name
ORDER BY sem.year DESC, sem.term, c.name;


-- Available faculty members
CREATE OR REPLACE VIEW available_faculty AS
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS instructor_name, 
	r.name AS title,
    u.email,
    u.phone_number,
    d.name AS department
 FROM employee e
	JOIN user u ON e.user_id = u.id
    JOIN department d ON e.department_id = d.id
    JOIN role r ON e.role_id = r.id
WHERE r.id = 1 OR r.id = 2;

-- Course grades summary
CREATE OR REPLACE VIEW course_grades AS
SELECT 
    c.name AS course_name,
    CONCAT(semester.term, ' ', semester.year) AS term,
    COUNT(e.section_id) AS total_students,
    SUM(CASE WHEN g.letter = 'A' AND g.type = 4 THEN 1 ELSE 0 END) AS grade_A,
    SUM(CASE WHEN g.letter = 'B' AND g.type = 4 THEN 1 ELSE 0 END) AS grade_B,
    SUM(CASE WHEN g.letter = 'C' AND g.type = 4 THEN 1 ELSE 0 END) AS grade_C,
    SUM(CASE WHEN g.letter = 'D' AND g.type = 4 THEN 1 ELSE 0 END) AS grade_D,
    SUM(CASE WHEN g.letter = 'F' AND g.type = 4 THEN 1 ELSE 0 END) AS grade_F
FROM section s
JOIN course c 
    ON s.course_id = c.id
JOIN semester 
    ON s.semester_id = semester.id
JOIN enrollment e 
    ON e.section_id = s.id
JOIN grade g 
    ON g.enrollment_id = e.id
WHERE g.type = 4
GROUP BY 
    s.id, c.name, semester.term, semester.year
ORDER BY 
    semester.year DESC;

-- Student transcript view
CREATE OR REPLACE VIEW student_transcript AS
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    c.name AS course,
    CONCAT(semester.term, ' ', semester.year) AS term,
    g.letter
FROM
    student s
        JOIN
    user u ON s.user_id = u.id
        JOIN
    enrollment e ON e.student_id = s.id
        JOIN
    section ON e.section_id = section.id
        JOIN
    semester ON section.semester_id = semester.id
        JOIN
    course c ON section.course_id = c.id
        JOIN
    grade g ON g.enrollment_id = e.id
WHERE
    g.type = 4
ORDER BY full_name;

-- STUDENT OVERVIEW
CREATE VIEW student_overview AS
SELECT s.id AS student_id,
		concat(u.first_name, " ", u.last_name) AS full_name,
        u.email,
        s.gpa,
        s.admission_date,
        COUNT(e.student_id) AS enrolled_classes
FROM student s
JOIN user u ON s.user_id = u.id
JOIN enrollment e ON s.id = e.student_id
GROUP BY s.id, u.first_name, u.last_name, u.email, s.gpa, s.admission_date;

-- INSTRUCTOR SCHEDULE
CREATE VIEW instructor_schedule AS
SELECT e.id AS employee_id,
		concat(u.first_name, " ", u.last_name) AS full_name,
        d.name AS department,
        c.name AS course_name,
        concat(m.term, " ", m.year) AS term,
        s.dow,
        concat(s.start_time, " - ", s.end_time) AS class_time,
        concat(b.name, " ",r.name) AS location
FROM employee e
JOIN user u ON e.user_id = u.id
JOIN department d ON d.id = e.department_id
JOIN section s ON s.instructor_id = e.id
JOIN semester m ON m.id = s.semester_id
JOIN section_room sr ON sr.section_id = s.id
JOIN room r ON r.id = sr.room_id
JOIN building b ON b.id = r.building
JOIN course c ON c.id = course_id
ORDER BY u.first_name ASC;

-- ROOM UTILIZATION
CREATE VIEW room_utilization AS
SELECT b.name AS building_name,
		r.name AS room_name,
        r.capacity,
		COUNT(DISTINCT sr.section_id) AS section_count,
        COUNT(DISTINCT e.student_id) AS filled_seats
FROM room r
JOIN building b ON b.id = r.building
JOIN section_room sr ON sr.room_id = r.id
JOIN section s ON s.id = sr.section_id
JOIN enrollment e ON e.section_id = s.id
GROUP BY b.name, r.name, r.capacity	

-- Building Supervisers
CREATE VIEW building_supervisers AS
SELECT b.name AS building_name,
		b.campus,
        concat(u.first_name, " ", u.last_name) AS supervisor,
        d.name AS department,
        u.phone_number
FROM building b
JOIN employee e ON e.id = b.building_supervisor
JOIN user u ON u.id = e.user_id
JOIN department d ON d.id = e.department_id

