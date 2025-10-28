# College Database EER Diagram

<img width="1190" height="878" alt="eer diagram" src="./assets/EER.png" />

*EER DIAGRAM*

---

## Table of Contents
- [Project Overview](#project-overview)
- [Tables and Descriptions](#tables-and-descriptions)
- [Common Columns](#common-columns)
- [Relationships](#relationships)
- [Views](#views)
- [Authors](#authors)

---

## Project Overview

![MariaDB](https://img.shields.io/badge/Database-MariaDB-blue)  
![EER](https://img.shields.io/badge/Model-EER%20Diagram-lightgrey)  
![Education](https://img.shields.io/badge/Project-Classroom%20Assignment-yellow)  

This project is a classroom assignment that models a college database using an Enhanced Entity-Relationship (EER) diagram.  
It captures data about users, students, employees, departments, courses, semesters, sections, rooms, buildings, enrollments, and grades.  
To simplify data retrieval and support common queries, several SQL views were added. These views join related tables to present combined information—such as student enrollments, instructor course assignments, and course offerings per semester—making it easier to analyze and display data without writing complex joins in every query.

The database is designed to:  
- Track users who may be students, employees, or other.  
- Manage course offerings, enrollments, and grades.  
- Handle departmental and building assignments.  
- Support classroom scheduling and room assignments.  

---

| Table Name           | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `user`              | Represents a person associated with the university (student, employee, or other). Stores personal info like name, date of birth, contact info, and university ID. |
| `student`           | Represents a student enrolled at the university; each student corresponds to a `user`. Tracks admission date, GPA, and current status. |
| `employee`          | Represents a university employee, including faculty or staff. Each employee corresponds to a `user` and belongs to a `department` and has a `role`. |
| `department`        | Represents an academic or administrative department at the university.     |
| `role`              | Represents a role assigned to an employee (e.g., Professor, Administrator).|
| `status`            | Represents the status of a student (e.g., Active, Alumnus, Leave of Absence).|
| `course`            | Represents an academic course offered by the university. Includes course name, description, and whether it is currently active. |
| `semester`          | Represents a university semester, including term (e.g., Fall) and year.    |
| `section`           | Represents a course section offered during a semester, taught by an employee (instructor), with day(s) of the week and start/end times. |
| `enrollment`        | Represents a student's enrollment in a specific section.                   |
| `grade_type`        | Represents the type of a grade (e.g., Midterm, Final, Project).            |
| `grade`             | Represents a grade assigned to a student's enrollment in a section, linked to a `grade_type`. |
| `building`          | Represents a university building, including its name, campus, and a supervising employee. |
| `room`              | Represents a room within a building, with capacity and optional description.|
| `section_room`      | Represents the many-to-many relationship between `section`s and `room`s. Allows a section to be assigned to multiple rooms and a room to host multiple sections. |

## Tables and Descriptions

### `user`
**Columns:**  
- `id` (PK) – Unique identifier  
- `first_name`, `last_name` – Name of the user  
- `dob` – Date of birth  
- `address`, `email`, `phone_number`, `ssn` – Contact and identification information  
- `university_id` – Unique university-specific identifier  

---

### `student`
**Columns:**  
- `id` (PK) – Unique identifier  
- `user_id` (FK → `user.id`) – Associated user  
- `admission_date` – Date of admission  
- `gpa` – Current grade point average  
- `status` (FK → `status.id`) – Current student status (e.g., Active, Alumnus)  

---

### `employee`
**Columns:**  
- `id` (PK) – Unique identifier  
- `user_id` (FK → `user.id`) – Associated user  
- `department_id` (FK → `department.id`) – Department where the employee works  
- `role_id` (FK → `role.id`) – Role or job title  

---

### `department`
**Columns:**  
- `id` (PK) – Unique identifier  
- `name` – Department name  

---

### `role`
**Columns:**  
- `id` (PK) – Unique identifier  
- `name` – Role name (e.g., Professor, Administrator)  
- `description` – Optional description of the role  

---

### `status`
**Columns:**  
- `id` (PK) – Unique identifier  
- `label` – Status label (e.g., Active, Alumnus)  
- `description` – Explanation of the status  

---

### `grade_type`
**Columns:**  
- `id` (PK) – Unique identifier  
- `name` – Grade type (e.g., Midterm, Final, Project)  

---

### `grade`
**Columns:**  
- `id` (PK) – Unique identifier  
- `letter` – Letter grade (e.g., A, B, C)  
- `enrollment_id` (FK → `enrollment.id`) – Enrollment associated with this grade  
- `type` (FK → `grade_type.id`) – Type of the grade  

---

### `enrollment`
**Columns:**  
- `id` (PK) – Unique identifier  
- `student_id` (FK → `student.id`) – Enrolled student  
- `section_id` (FK → `section.id`) – Section the student is enrolled in  

---

### `section`
**Columns:**  
- `id` (PK) – Unique identifier  
- `semester_id` (FK → `semester.id`) – Semester the section is offered in  
- `course_id` (FK → `course.id`) – Associated course  
- `instructor_id` (FK → `employee.id`) – Instructor assigned to the section  
- `dow` – Day(s) of the week  
- `start_time`, `end_time` – Scheduled times  

---

### `course`
**Columns:**  
- `id` (PK) – Unique identifier  
- `name` – Course name  
- `description` – Course description  
- `active` – Indicates if the course is currently active (TINYINT)  

---

### `semester`
**Columns:**  
- `id` (PK) – Unique identifier  
- `term` – Term name (e.g., Fall, Spring)  
- `year` – Calendar year  

---

### `building`
**Columns:**  
- `id` (PK) – Unique identifier  
- `name` – Building name  
- `building_supervisor` (FK → `employee.id`) – Employee supervising the building  
- `campus` – Campus location   

---

### `room`
**Columns:**  
- `id` (PK) – Unique identifier  
- `name` – Room name or number  
- `building` (FK → `building.id`) – Building containing the room  
- `capacity` – Number of occupants the room can hold  
- `description` – Additional notes about the room  

---

### `section_room`
**Columns:**  
- `id` (PK) – Unique identifier  
- `room_id` (FK → `room.id`) – Assigned room  
- `section_id` (FK → `section.id`) – Section scheduled in the room  

---

## Common Columns
All tables include the following audit columns:  
- `created` (TIMESTAMP) – Record creation timestamp  
- `created_userid` (INT) – User ID who created the record  
- `updated` (TIMESTAMP) – Last update timestamp  
- `updated_userid` (INT) – User ID who last updated the record  

---

## Relationships
- `user` → `student` / `employee` (1-to-0..1)  
- `student` → `status` (many-to-1)  
- `student` → `enrollment` (1-to-many)  
- `enrollment` → `grade` (1-to-many)  
- `grade` → `grade_type` (many-to-1)  
- `employee` → `department` / `role` (many-to-1)  
- `building` → `employee` (`building_supervisor`) (many-to-1)  
- `room` → `building` (many-to-1)  
- `section` → `course` / `semester` / `employee` (`instructor_id`) (many-to-1)  
- `section_room` → `section` / `room` (many-to-many)   

---

## Views

### `course_offerings`
**Purpose:**  
Displays all course sections offered in each semester, including instructor, schedule, assigned rooms, and enrollment statistics. Helps administrators and students see available courses, capacities, and remaining seats.  
![alt text](assets/course_offerings.png)

---

### `available_faculty`
**Purpose:**  
Lists faculty members who are available for teaching assignments. Useful for scheduling new sections or finding substitute instructors.  
![alt text](assets/available_faculty.png)

---

### `course_grades`
**Purpose:**  
Summarizes grades for each course section, providing a grade distribution overview. Useful for analyzing student performance.  
![alt text](assets/course_grades.png)

---

### `student_transcript`
**Purpose:**  
Provides a complete transcript for students, showing courses taken and final grades. Useful for advisors, registrars, and students.  
![alt text](assets/student_transcript.png)

---

### `student_overview`
**Purpose:**
Provides a general overview of the students, including email, admission date, GPA, and the number of currently enrolled classes Useful if quick information is needed about a student.
![alt text](assets/student_overview.png)

---

### `instructor_schedule`
**Purpose:**
Provides a complete list of professors and the classes they teach, the time it takes place, the location, day of the week, and semester it takes place in. Useful to students to see the schedule of any given professor.
![alt text](assets/instructor_schedule.png)

---

### `room_utilization`
**Purpose:**
Provides a complete list of all rooms and the amount of sections taking place inside of it. This would be useful for anyone needing to use the room.</br>
![alt text](assets/room_utilization.png)

---

### `building_supervisors`
**Purpose:**
Provides a list of all buildings on campus and their supervisors with contact information. This would be helpful for requesting maintenance for the building or for permission to do something in the building.
![alt text](assets/building_supervisor.png)

---

## Authors
- [Nicolas Tagliafichi](https://github.com/nicotaglia14)  
- [Brayden Hermanson](https://github.com/brherm05)  
