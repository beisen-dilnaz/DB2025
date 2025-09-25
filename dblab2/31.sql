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