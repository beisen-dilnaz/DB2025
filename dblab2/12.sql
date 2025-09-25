CREATE TABLESPACE student_data
    LOCATION '/Users/Shared/pgdata/students';

CREATE TABLESPACE course_data
    OWNER CURRENT_USER
    LOCATION '/Users/Shared/pgdata/courses';

CREATE DATABASE university_distributed
    WITH TEMPLATE = template0
         ENCODING  = 'LATIN9'
         TABLESPACE = student_data;