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