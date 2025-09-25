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