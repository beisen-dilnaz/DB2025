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