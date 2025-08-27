-- ============================================
-- Student Records Database (MySQL 8+)
-- CREATE TABLE statements only (no data)
-- Relationships covered:
--   • 1–M: departments→programs, programs→students, courses→sections, instructors→sections
--   • 1–1: students↔student_profile
--   • M–M: programs↔courses (program_courses), students↔sections (enrollments)
-- ============================================

-- Use consistent defaults
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------
-- Core reference tables
-- -----------------------

CREATE TABLE departments (
  dept_id        INT AUTO_INCREMENT PRIMARY KEY,
  dept_name      VARCHAR(100) NOT NULL,
  dept_email     VARCHAR(150) NOT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_departments_name (dept_name),
  UNIQUE KEY uq_departments_email (dept_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE programs (
  program_id     INT AUTO_INCREMENT PRIMARY KEY,
  dept_id        INT NOT NULL,
  program_name   VARCHAR(120) NOT NULL,
  degree_level   ENUM('CERTIFICATE','DIPLOMA','BACHELOR','MASTERS','PHD') NOT NULL,
  duration_semesters TINYINT UNSIGNED NOT NULL DEFAULT 8,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_programs_department
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_program_name_per_dept (dept_id, program_name),
  CHECK (duration_semesters BETWEEN 1 AND 16)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- People
-- -----------------------

CREATE TABLE students (
  student_id     VARCHAR(12) PRIMARY KEY,              -- e.g., STU000123
  program_id     INT NOT NULL,
  first_name     VARCHAR(60) NOT NULL,
  last_name      VARCHAR(60) NOT NULL,
  dob            DATE NOT NULL,
  gender         ENUM('MALE','FEMALE','OTHER','PREFER_NOT_SAY') NOT NULL,
  email          VARCHAR(150) NOT NULL,
  phone          VARCHAR(30) NOT NULL,
  admission_date DATE NOT NULL,
  status         ENUM('ACTIVE','SUSPENDED','GRADUATED','WITHDRAWN') NOT NULL DEFAULT 'ACTIVE',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_students_program
    FOREIGN KEY (program_id) REFERENCES programs(program_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_students_email (email),
  UNIQUE KEY uq_students_phone (phone),
  CHECK (admission_date >= DATE('1970-01-01'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1–1 extension of student (same PK as FK ensures true one-to-one)
CREATE TABLE student_profile (
  student_id     VARCHAR(12) PRIMARY KEY,
  national_id    VARCHAR(30) NOT NULL,
  address_line1  VARCHAR(150) NOT NULL,
  address_line2  VARCHAR(150) NULL,
  city           VARCHAR(80) NOT NULL,
  region         VARCHAR(80) NULL,
  postal_code    VARCHAR(20) NULL,
  guardian_name  VARCHAR(120) NULL,
  guardian_phone VARCHAR(30) NULL,
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_profile_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE KEY uq_profile_national_id (national_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE instructors (
  instructor_id  INT AUTO_INCREMENT PRIMARY KEY,
  dept_id        INT NOT NULL,
  first_name     VARCHAR(60) NOT NULL,
  last_name      VARCHAR(60) NOT NULL,
  email          VARCHAR(150) NOT NULL,
  phone          VARCHAR(30) NULL,
  hire_date      DATE NOT NULL,
  CONSTRAINT fk_instructors_department
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_instructors_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Curriculum / Courses
-- -----------------------

CREATE TABLE courses (
  course_id      VARCHAR(15) PRIMARY KEY,              -- e.g., CS101
  dept_id        INT NOT NULL,
  course_title   VARCHAR(150) NOT NULL,
  credits        TINYINT UNSIGNED NOT NULL,            -- 1..10
  level          ENUM('L1','L2','L3','L4','GRAD') NOT NULL,
  CONSTRAINT fk_courses_department
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (credits BETWEEN 1 AND 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- M–M: which courses belong to which programs (and whether core/elective)
CREATE TABLE program_courses (
  program_id     INT NOT NULL,
  course_id      VARCHAR(15) NOT NULL,
  semester_no    TINYINT UNSIGNED NOT NULL,            -- recommended semester
  is_core        BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (program_id, course_id),
  CONSTRAINT fk_prog_courses_program
    FOREIGN KEY (program_id) REFERENCES programs(program_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_prog_courses_course
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (semester_no BETWEEN 1 AND 16)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sections (offerings of a course in a particular term)
CREATE TABLE course_sections (
  section_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  course_id      VARCHAR(15) NOT NULL,
  instructor_id  INT NOT NULL,
  section_no     SMALLINT UNSIGNED NOT NULL DEFAULT 1, -- 1,2,3...
  term           ENUM('SPRING','SUMMER','FALL') NOT NULL,
  year_offered   YEAR NOT NULL,
  capacity       SMALLINT UNSIGNED NOT NULL DEFAULT 40,
  CONSTRAINT fk_sections_course
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_sections_instructor
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_course_term_year_section (course_id, term, year_offered, section_no),
  CHECK (capacity BETWEEN 1 AND 500)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Enrollment (M–M students↔sections)
-- -----------------------

CREATE TABLE enrollments (
  student_id     VARCHAR(12) NOT NULL,
  section_id     BIGINT NOT NULL,
  enrolled_on    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  grade_letter   ENUM('A','B','C','D','E','F','I','W') NULL,
  PRIMARY KEY (student_id, section_id),
  CONSTRAINT fk_enroll_student
    FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_enroll_section
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- End of schema
-- ============================================
