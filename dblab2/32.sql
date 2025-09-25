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