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