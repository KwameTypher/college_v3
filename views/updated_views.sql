-- =========================================
-- 1) Course offerings with enrollment count
-- =========================================
CREATE OR REPLACE VIEW course_offerings AS
SELECT
    s.id AS section_id,
    c.name AS course_name,
    sem.term,
    sem.year,
    s.dow,
    CONCAT(TIME_FORMAT(s.start_time, '%H:%i'), ' - ', TIME_FORMAT(s.end_time, '%H:%i')) AS time,
    CONCAT(u.first_name, ' ', u.last_name) AS instructor_name,
    GROUP_CONCAT(DISTINCT CONCAT(b.name, ' ', r.name) ORDER BY b.name, r.name SEPARATOR ', ') AS rooms,
    SUM(r.capacity) AS capacity,
    COUNT(DISTINCT e.student_id) AS total_enrolled,
    GREATEST(SUM(r.capacity) - COUNT(DISTINCT e.student_id), 0) AS remaining_seats
FROM section s
JOIN course c           ON s.course_id = c.id
JOIN semester sem       ON s.semester_id = sem.id
JOIN employee emp       ON s.instructor_id = emp.id
JOIN `user` u           ON emp.user_id = u.id
JOIN section_room sr    ON sr.section_id = s.id
JOIN room r             ON r.id = sr.room_id
JOIN building b         ON b.id = r.building
LEFT JOIN enrollment e  ON e.section_id = s.id
GROUP BY
    s.id, c.name, sem.term, sem.year,
    s.dow, s.start_time, s.end_time,
    u.first_name, u.last_name
ORDER BY sem.year DESC,
         FIELD(sem.term,'Fall','Summer','Spring'),
         c.name;

-- ==========================
-- 2) Available faculty list
-- ==========================
CREATE OR REPLACE VIEW available_faculty AS
SELECT
    CONCAT(u.first_name, ' ', u.last_name) AS instructor_name,
    r.name AS title,
    u.email,
    u.phone_number,
    d.name AS department
FROM employee e
JOIN `user` u     ON e.user_id = u.id
JOIN department d ON e.department_id = d.id
JOIN role r       ON e.role_id = r.id
WHERE r.name IN ('Professor','Associate Professor','Assistant Professor','Lecturer','Adjunct');

-- =========================
-- 3) Course grades summary
-- =========================
CREATE OR REPLACE VIEW course_grades AS
SELECT
    s.id AS section_id,
    c.name AS course_name,
    CONCAT(sem.term, ' ', sem.year) AS term,
    COUNT(DISTINCT e.id) AS total_students,
    SUM(CASE WHEN g.letter = 'A' THEN 1 ELSE 0 END) AS grade_A,
    SUM(CASE WHEN g.letter = 'B' THEN 1 ELSE 0 END) AS grade_B,
    SUM(CASE WHEN g.letter = 'C' THEN 1 ELSE 0 END) AS grade_C,
    SUM(CASE WHEN g.letter = 'D' THEN 1 ELSE 0 END) AS grade_D,
    SUM(CASE WHEN g.letter = 'F' THEN 1 ELSE 0 END) AS grade_F
FROM section s
JOIN course c        ON s.course_id = c.id
JOIN semester sem    ON s.semester_id = sem.id
JOIN enrollment e    ON e.section_id = s.id
JOIN grade g         ON g.enrollment_id = e.id
JOIN grade_type gt   ON gt.id = g.type AND gt.name = 'Final'
GROUP BY
    s.id, c.name, sem.term, sem.year
ORDER BY sem.year DESC,
         FIELD(sem.term,'Fall','Summer','Spring');

-- ======================
-- 4) Student transcript
-- ======================
CREATE OR REPLACE VIEW student_transcript AS
SELECT
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    c.name AS course,
    CONCAT(sem.term, ' ', sem.year) AS term,
    g.letter
FROM student st
JOIN `user` u      ON st.user_id = u.id
JOIN enrollment e  ON e.student_id = st.id
JOIN section s     ON s.id = e.section_id
JOIN semester sem  ON sem.id = s.semester_id
JOIN course c      ON c.id = s.course_id
JOIN grade g       ON g.enrollment_id = e.id
JOIN grade_type gt ON gt.id = g.type AND gt.name = 'Final'
ORDER BY full_name, sem.year,
         FIELD(sem.term,'Fall','Summer','Spring'),
         c.name;

-- ===================
-- 5) Student overview
-- ===================
CREATE OR REPLACE VIEW student_overview AS
SELECT
    st.id AS student_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.email,
    st.gpa,
    st.admission_date,
    COALESCE(COUNT(DISTINCT e.id), 0) AS enrolled_classes
FROM student st
JOIN `user` u      ON st.user_id = u.id
LEFT JOIN enrollment e ON e.student_id = st.id
GROUP BY
    st.id, u.first_name, u.last_name, u.email, st.gpa, st.admission_date;

-- ======================
-- 6) Instructor schedule
-- ======================
CREATE OR REPLACE VIEW instructor_schedule AS
SELECT
    e.id AS employee_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    d.name AS department,
    c.name AS course_name,
    CONCAT(sem.term, ' ', sem.year) AS term,
    s.dow,
    CONCAT(TIME_FORMAT(s.start_time, '%H:%i'), ' - ', TIME_FORMAT(s.end_time, '%H:%i')) AS class_time,
    GROUP_CONCAT(DISTINCT CONCAT(b.name, ' ', r.name) ORDER BY b.name, r.name SEPARATOR ', ') AS location
FROM employee e
JOIN `user` u       ON e.user_id = u.id
JOIN department d   ON d.id = e.department_id
JOIN section s      ON s.instructor_id = e.id
JOIN semester sem   ON sem.id = s.semester_id
JOIN section_room sr ON sr.section_id = s.id
JOIN room r         ON r.id = sr.room_id
JOIN building b     ON b.id = r.building
JOIN course c       ON c.id = s.course_id
GROUP BY
    e.id, u.first_name, u.last_name, d.name,
    c.name, sem.term, sem.year,
    s.dow, s.start_time, s.end_time, s.id
ORDER BY u.first_name, u.last_name, sem.year DESC,
         FIELD(sem.term,'Fall','Summer','Spring');

-- ==================
-- 7) Room utilization
-- ==================
CREATE OR REPLACE VIEW room_utilization AS
SELECT
    b.name AS building_name,
    r.name AS room_name,
    r.capacity,
    COUNT(DISTINCT sr.section_id) AS section_count,
    COUNT(DISTINCT e.id) AS filled_seats
FROM room r
JOIN building b        ON b.id = r.building
LEFT JOIN section_room sr ON sr.room_id = r.id
LEFT JOIN section s        ON s.id = sr.section_id
LEFT JOIN enrollment e      ON e.section_id = s.id
GROUP BY b.name, r.name, r.capacity;

-- ==================================================
-- 8) Building supervisors  (fix spelling + keep old)
-- ==================================================
CREATE OR REPLACE VIEW building_supervisors AS
SELECT
    b.name AS building_name,
    b.campus,
    CONCAT(u.first_name, ' ', u.last_name) AS supervisor,
    d.name AS department,
    u.phone_number
FROM building b
JOIN employee e  ON e.id = b.building_supervisor
JOIN `user` u    ON u.id = e.user_id
JOIN department d ON d.id = e.department_id;

-- Backwards-compatible alias with original misspelling
CREATE OR REPLACE VIEW building_supervisers AS
SELECT * FROM building_supervisors;




-- What changed:

-- Replaced hard-coded g.type = 4 with a join to grade_type on name = 'Final'.

-- Made enrollment and utilization counts COUNT(DISTINCT ...) to avoid duplicates.

-- Aggregated multi-room sections with GROUP_CONCAT, and used SUM(r.capacity) for capacity.

-- Used LEFT JOIN in places where “zero” should be represented (e.g., rooms with no sections, students with no enrollments).

-- Fixed join bugs (e.g., JOIN course c ON c.id = s.course_id) and ensured all non-aggregated columns are in GROUP BY.

-- Added a correctly spelled building_supervisors view but kept building_supervisers as a compatibility alias.