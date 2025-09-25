-- 1.1
CREATE DATABASE university_main
    OWNER CURRENT_USER
    TEMPLATE template0
    ENCODING 'UTF8';

CREATE DATABASE university_archive
    TEMPLATE template0
    CONNECTION LIMIT 50;

CREATE DATABASE university_test
    IS_TEMPLATE TRUE
    CONNECTION LIMIT 10;

-- 1.2
CREATE TABLESPACE student_data
    LOCATION '/Users/Shared/pgdata/students';

CREATE TABLESPACE course_data
    OWNER CURRENT_USER
    LOCATION '/Users/Shared/pgdata/courses';

CREATE DATABASE university_distributed
    WITH TEMPLATE = template0
         ENCODING  = 'LATIN9'
         TABLESPACE = student_data;

-- 2.1
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,                  
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone CHAR(15),                                 
    date_of_birth DATE NOT NULL,
    enrollment_date DATE NOT NULL,
    gpa NUMERIC(3,2),                              
    is_active BOOLEAN DEFAULT TRUE,
    graduation_year SMALLINT
);

CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    office_number VARCHAR(20),
    hire_date DATE NOT NULL,
    salary NUMERIC(12,2),                           
    is_tenured BOOLEAN DEFAULT FALSE,
    years_experience INT
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8) UNIQUE NOT NULL,            
    course_title VARCHAR(100) NOT NULL,
    description TEXT,                               
    credits SMALLINT NOT NULL,
    max_enrollment INT,
    course_fee NUMERIC(10,2),
    is_online BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2.2
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL,
    professor_id INT NOT NULL,
    classroom VARCHAR(20),
    class_date DATE NOT NULL,
    start_time TIME WITHOUT TIME ZONE NOT NULL,
    end_time TIME WITHOUT TIME ZONE NOT NULL,
    duration INTERVAL,

    CONSTRAINT fk_class_schedule_course
        FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT fk_class_schedule_professor
        FOREIGN KEY (professor_id) REFERENCES professors(professor_id)
);

CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    semester VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    grade CHAR(2),                                      
    attendance_percentage NUMERIC(4,1),                
    submission_timestamp TIMESTAMPTZ DEFAULT NOW(),
    last_updated TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_student_records_student
        FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_student_records_course
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

-- 3.1
ALTER TABLE students
    ADD COLUMN middle_name VARCHAR(30),
    ADD COLUMN student_status VARCHAR(20) DEFAULT 'ACTIVE';

ALTER TABLE students
    ALTER COLUMN phone TYPE VARCHAR(20);

ALTER TABLE students
    ALTER COLUMN gpa SET DEFAULT 0.00;

ALTER TABLE professors
    ADD COLUMN department_code CHAR(5),
    ADD COLUMN research_area TEXT,
    ADD COLUMN last_promotion_date DATE;

ALTER TABLE professors
    ALTER COLUMN years_experience TYPE SMALLINT;

ALTER TABLE professors
    ALTER COLUMN is_tenured SET DEFAULT FALSE;

ALTER TABLE courses
    ADD COLUMN prerequisite_course_id INT,
    ADD COLUMN difficulty_level SMALLINT,
    ADD COLUMN lab_required BOOLEAN DEFAULT FALSE;

ALTER TABLE courses
    ALTER COLUMN course_code TYPE VARCHAR(10);

ALTER TABLE courses
    ALTER COLUMN credits SET DEFAULT 3;

-- 3.2
ALTER TABLE class_schedule
    ADD COLUMN IF NOT EXISTS room_capacity INT,
    ADD COLUMN IF NOT EXISTS session_type VARCHAR(15),
    ADD COLUMN IF NOT EXISTS equipment_needed TEXT;

ALTER TABLE class_schedule
    DROP COLUMN IF EXISTS duration;

ALTER TABLE class_schedule
    ALTER COLUMN classroom TYPE VARCHAR(30);

ALTER TABLE student_records
    ADD COLUMN IF NOT EXISTS extra_credit_points NUMERIC(4,1) DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS final_exam_date DATE;

ALTER TABLE student_records
    ALTER COLUMN grade TYPE VARCHAR(5);

ALTER TABLE student_records
    ALTER COLUMN extra_credit_points SET DEFAULT 0.0;

ALTER TABLE student_records
    DROP COLUMN IF EXISTS last_updated;

-- 4.1
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code CHAR(5) UNIQUE NOT NULL,
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(15,2),
    established_year INT
);

CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(10,2),
    is_available BOOLEAN DEFAULT TRUE,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount NUMERIC(10,2) DEFAULT 0.00,
    loan_status VARCHAR(20) DEFAULT 'ONGOING',

    CONSTRAINT fk_loan_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_loan_book FOREIGN KEY (book_id) REFERENCES library_books(book_id)
);

-- 4.2
ALTER TABLE professors
    ADD COLUMN department_id INT;

ALTER TABLE students
    ADD COLUMN advisor_id INT;

ALTER TABLE courses
    ADD COLUMN department_id INT;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL UNIQUE,
    min_percentage NUMERIC(5,1) NOT NULL,  
    max_percentage NUMERIC(5,1) NOT NULL,   
    gpa_points NUMERIC(3,2) NOT NULL        
);

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,    
    academic_year INT NOT NULL,           
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,
    is_current BOOLEAN DEFAULT FALSE
);

-- 5.1
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL UNIQUE,
    min_percentage NUMERIC(5,1) NOT NULL,
    max_percentage NUMERIC(5,1) NOT NULL,
    gpa_points NUMERIC(3,2) NOT NULL,
    description TEXT
);

DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,
    is_current BOOLEAN DEFAULT FALSE
);

-- 5.2
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup
    TEMPLATE university_main;
