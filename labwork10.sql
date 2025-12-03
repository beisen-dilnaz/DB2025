CREATE TABLE IF NOT EXISTS bank_account (
    account_id   INT PRIMARY KEY,
    owner_name   TEXT,
    balance      NUMERIC(10,2)
);

INSERT INTO bank_account (account_id, owner_name, balance) VALUES
(1, 'Alice', 1000.00),
(2, 'Bob',   500.00)
ON CONFLICT (account_id) DO NOTHING;

--2.1
BEGIN;
UPDATE bank_account SET balance = balance - 100 WHERE account_id = 1;
UPDATE bank_account SET balance = balance + 100 WHERE account_id = 2;
COMMIT;

--2.2
BEGIN;
UPDATE bank_account SET balance = balance + 200 WHERE account_id = 1;
ROLLBACK;

--2.3
BEGIN;
UPDATE bank_account SET balance = balance - 50 WHERE account_id = 1;
SAVEPOINT sp_after_first_update;
UPDATE bank_account SET balance = balance - 50 WHERE account_id = 2;
ROLLBACK TO sp_after_first_update;
COMMIT;

--2.4
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
SELECT * FROM bank_account;
COMMIT;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT * FROM bank_account;
COMMIT;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN;
SELECT * FROM bank_account;
COMMIT;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN;
SELECT * FROM bank_account;
COMMIT;


--3.1 
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob',   500.00),
('Wally', 750.00)
ON CONFLICT DO NOTHING;

INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke',  2.50),
('Joe''s Shop', 'Pepsi', 3.00),
('Joe''s Shop', 'Fanta', 3.50)
ON CONFLICT DO NOTHING;

--3.2 
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;

--3.3 
BEGIN;
UPDATE accounts SET balance = balance - 500.00
WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

--3.4 
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
SAVEPOINT sp1;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
SAVEPOINT sp2;
ROLLBACK TO sp1;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Wally';
COMMIT;

--3.5 
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';

SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--3.5 
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

--3.5 
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';

SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--3.5 
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

--3.6 
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price)
FROM products
WHERE shop = 'Joe''s Shop';

SELECT MAX(price), MIN(price)
FROM products
WHERE shop = 'Joe''s Shop';
COMMIT;

--3.6 
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

--3.7 
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';

SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--3.7 
BEGIN;
UPDATE products SET price = 99.99
WHERE product = 'Fanta';

ROLLBACK;

--4.1 
BEGIN;
UPDATE accounts
SET balance = balance - 200.00
WHERE name = 'Bob' AND balance >= 200.00;
UPDATE accounts
SET balance = balance + 200.00
WHERE name = 'Wally';
COMMIT;

--4.2 
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Water', 1.00);
SAVEPOINT sp_first;
UPDATE products
SET price = 1.50
WHERE shop = 'Joe''s Shop' AND product = 'Water';
SAVEPOINT sp_second;
DELETE FROM products
WHERE shop = 'Joe''s Shop' AND product = 'Water';
ROLLBACK TO sp_first;
COMMIT;

--4.3 
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 300.00
WHERE name = 'Alice';

COMMIT;

--4.3 
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 300.00
WHERE name = 'Alice';
COMMIT;

--4.3 
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 300.00
WHERE name = 'Alice';

COMMIT;

--4.3 
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 300.00
WHERE name = 'Alice';
COMMIT;

--4.4 
CREATE TABLE IF NOT EXISTS sells (
    shop VARCHAR(100),
    product VARCHAR(100),
    price DECIMAL(10,2)
);

INSERT INTO sells (shop, product, price) VALUES
('Joe''s Shop', 'Tea',   1.00),
('Joe''s Shop', 'Coffee',2.00),
('Joe''s Shop', 'Juice', 4.00);


SELECT MAX(price) FROM sells WHERE shop = 'Joe''s Shop';
SELECT MIN(price) FROM sells WHERE shop = 'Joe''s Shop';


BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT MAX(price) FROM sells WHERE shop = 'Joe''s Shop';
SELECT MIN(price) FROM sells WHERE shop = 'Joe''s Shop';
COMMIT;


BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE sells SET price = 10.00 WHERE product = 'Tea';
DELETE FROM sells WHERE product = 'Juice';
COMMIT;