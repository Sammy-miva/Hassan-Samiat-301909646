INSERT INTO customers (first_name, last_name, email, phone, date_of_birth) VALUES
('Demo', 'Sender',   'demo.sender@samypay.test',   '08000000001', '1990-01-01'),
('Demo', 'Receiver', 'demo.receiver@samypay.test', '08000000002', '1992-02-02');

INSERT INTO accounts (account_number, customer_id, branch_id, account_type, balance)
VALUES
('9000000001',
 (SELECT customer_id FROM customers WHERE email = 'demo.sender@samypay.test'),
 (SELECT min(branch_id) FROM branches), 'SAVINGS', 100000),
('9000000002',
 (SELECT customer_id FROM customers WHERE email = 'demo.receiver@samypay.test'),
 (SELECT min(branch_id) FROM branches), 'SAVINGS', 50000);