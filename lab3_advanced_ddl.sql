-- A
CREATE TABLE employees (
    emp_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    department  VARCHAR(50)  NOT NULL,
    salary      INTEGER      NOT NULL CHECK (salary >= 0),
    hire_date   DATE         NOT NULL DEFAULT CURRENT_DATE,
    status      VARCHAR(20)  NOT NULL DEFAULT 'Active'
                  CHECK (status IN ('Active', 'On Leave', 'Terminated'))
);

CREATE TABLE departments (
    dept_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name   VARCHAR(100) NOT NULL UNIQUE,
    budget      INTEGER      NOT NULL CHECK (budget >= 0),
    manager_id  INTEGER      NULL,
    CONSTRAINT fk_departments_manager
        FOREIGN KEY (manager_id)
        REFERENCES employees(emp_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE projects (
    project_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL,
    dept_id      INTEGER      NOT NULL,
    start_date   DATE         NOT NULL,
    end_date     DATE,
    budget       INTEGER      NOT NULL CHECK (budget >= 0),
    CONSTRAINT fk_projects_dept
        FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_project_dates
        CHECK (end_date IS NULL OR end_date >= start_date)
);

-- B
ALTER TABLE employees
ALTER COLUMN salary SET DEFAULT 0;

INSERT INTO employees (emp_id, first_name, last_name, department)
OVERRIDING SYSTEM VALUE
VALUES (10, 'Amir', 'Kapasov', 'Finance');

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Ingkar', 'Adilbek', 'HR', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
  ('Finance',    5000000, NULL),
  ('Marketing',  3000000, NULL),
  ('Operations', 7000000, NULL);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Dilnaz', 'Beisenova', 'IT', 50000 * 1.1, CURRENT_DATE);

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

-- C
UPDATE employees
SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

ALTER TABLE employees
ALTER COLUMN department SET DEFAULT 'General';

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.20
    FROM employees e
    WHERE e.department = d.dept_name
);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- D
DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

DELETE FROM departments d
WHERE d.dept_name NOT IN (
    SELECT DISTINCT e.department
    FROM employees e
    WHERE e.department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- E
ALTER TABLE employees
ALTER COLUMN salary DROP NOT NULL;

ALTER TABLE employees
ALTER COLUMN department DROP NOT NULL;

INSERT INTO employees (first_name, last_name, salary, department, hire_date, status)
VALUES ('Dana', 'Daniyarkyzy', NULL, NULL, CURRENT_DATE, 'Active');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;


-- F
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Adilzhan', 'Daurenov', 'Finance', 450000, CURRENT_DATE, 'Active')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- G
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'Dauletkhan', 'Amangel', 'HR', 300000, CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Dauletkhan'
      AND last_name  = 'Amangel'
);

UPDATE employees e
SET salary = salary *
    (CASE
        WHEN (SELECT d.budget
              FROM departments d
              WHERE d.dept_name = e.department) > 100000
        THEN 1.10
        ELSE 1.05
    END);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
 ('Aigerim', 'Nur', 'Sales', 200000, CURRENT_DATE, 'Active'),
 ('Dias', 'Ualikhan', 'Finance', 250000, CURRENT_DATE, 'Active'),
 ('Alina', 'Kairat', 'IT', 300000, CURRENT_DATE, 'Active'),
 ('Serik', 'Asan', 'HR', 220000, CURRENT_DATE, 'Active'),
 ('Dana', 'Yerlan', 'Marketing', 280000, CURRENT_DATE, 'Active');

CREATE TABLE employee_archive AS
SELECT *
FROM employees
WHERE 1=0;

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
    SELECT COUNT(*)
    FROM employees e
    WHERE e.department = (
        SELECT d.dept_name
        FROM departments d
        WHERE d.dept_id = p.dept_id
    )
  ) > 3;