-- 1.1
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

INSERT INTO employees VALUES (1, 'Dilnaz', 'Beisen', 25, 5000);
INSERT INTO employees VALUES (2, 'Ingkar', 'Adilbek', 64, 7000);

-- 1.2
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

INSERT INTO products_catalog VALUES (1, 'macbook', 120, 90);
INSERT INTO products_catalog VALUES (2, 'airpods', 80, 60);

-- 1.3
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO bookings VALUES (1, '2025-05-01', '2025-05-05', 2);
INSERT INTO bookings VALUES (2, '2025-06-10', '2025-06-12', 4);

-- 2.1
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

INSERT INTO customers VALUES (1, 'dilnaz@mail.com', '87071234567', '2025-01-10');
INSERT INTO customers VALUES (2, 'adil@mail.com', NULL, '2025-02-01');

-- 2.2
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory VALUES (1, 'Mouse', 10, 15.99, NOW());
INSERT INTO inventory VALUES (2, 'Monitor', 5, 250.00, NOW());

-- 3.1
CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

INSERT INTO users VALUES (1, 'admin', 'admin@mail.com', NOW());
INSERT INTO users VALUES (2, 'user', 'user@mail.com', NOW());

-- 3.2
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 101, 'DB101', 'Fall');
INSERT INTO course_enrollments VALUES (2, 101, 'CS102', 'Fall');

-- 3.3
ALTER TABLE users
    ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email UNIQUE (email);

-- 4.1
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (1, 'IT', 'Building A');
INSERT INTO departments VALUES (2, 'HR', 'Building B');
INSERT INTO departments VALUES (3, 'Finance', 'Building C');

-- 4.2
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (1, 101, '2025-02-01', 'A');
INSERT INTO student_courses VALUES (2, 101, '2025-02-01', 'B');

-- 5.1
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Alina', 1, '2024-01-01');
INSERT INTO employees_dept VALUES (2, 'Madina', 3, '2024-02-01');

-- 5.2
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK'), (2, 'George Orwell', 'UK');
INSERT INTO publishers VALUES (1, 'Penguin', 'London'), (2, 'Bloomsbury', 'Oxford');
INSERT INTO books VALUES (1, '1984', 2, 1, 1949, '1234567890123');
INSERT INTO books VALUES (2, 'Harry Potter', 1, 2, 1997, '9876543210987');

-- 5.3
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO products_fk VALUES (1, 'Laptop', 1);
INSERT INTO orders VALUES (1, '2025-03-01');
INSERT INTO order_items VALUES (1, 1, 1, 2);
DELETE FROM orders WHERE order_id = 1;

-- 6.1
CREATE TABLE customers_ecom (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products_ecom (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers_ecom(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC(10,2) CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_ecom(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC(10,2) CHECK (unit_price >= 0)
);

INSERT INTO customers_ecom (name, email, phone, registration_date)
VALUES 
('Dilnaz Beisen', 'dilya@mail.com', '87071234567', CURRENT_DATE),
('Ingkar Adilbek', 'inko@mail.com', NULL, CURRENT_DATE),
('Adilzhan Dauren', 'adik@mail.com', '87074561234', CURRENT_DATE),
('Magzhan Yerlan', 'maga@mail.com', '87079876543', CURRENT_DATE),
('Adele Kikbay', 'adele@mail.com', NULL, CURRENT_DATE);

INSERT INTO products_ecom (name, description, price, stock_quantity)
VALUES
('Laptop', '15-inch model', 850.00, 20),
('Mouse', 'Wireless optical mouse', 25.00, 100),
('Keyboard', 'Mechanical RGB keyboard', 75.00, 50),
('Monitor', '27-inch 4K display', 300.00, 30),
('USB Cable', '1m Type-C', 10.00, 200);

INSERT INTO orders_ecom (customer_id, order_date, total_amount, status)
VALUES
(1, CURRENT_DATE, 875.00, 'pending'),
(2, CURRENT_DATE, 25.00, 'processing'),
(3, CURRENT_DATE, 300.00, 'delivered'),
(4, CURRENT_DATE, 385.00, 'shipped'),
(5, CURRENT_DATE, 100.00, 'cancelled');

INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES
(1, 1, 1, 850.00),
(1, 2, 1, 25.00),
(2, 2, 1, 25.00),
(3, 4, 1, 300.00),
(4, 3, 5, 77.00);