-- SamyPay sample data (simulated). Run once on an empty database.

-- SamyPay sample data (simulated). Run once on an empty database.

-- Transaction types
INSERT INTO transaction_types (type_name)
VALUES ('DEPOSIT'), ('WITHDRAWAL'), ('TRANSFER'), ('REVERSAL')
ON CONFLICT (type_name) DO NOTHING;

-- Branches
INSERT INTO branches (branch_name, city) VALUES
('Ikeja Branch', 'Lagos'),
('Victoria Island Branch', 'Lagos'),
('Wuse Branch', 'Abuja'),
('Garki Branch', 'Abuja'),
('Port Harcourt Branch', 'Port Harcourt'),
('Kano Branch', 'Kano'),
('Ibadan Branch', 'Ibadan'),
('Enugu Branch', 'Enugu');

-- 5,000 customers
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth)
SELECT
  (ARRAY['Mariam','Ade','Bola','Chika','Emeka','Fatima','Ibrahim','Ngozi','Tunde','Zainab'])[1 + g % 10],
  (ARRAY['Adamu','Bello','Okafor','Musa','Eze','Yusuf','Balogun','Nwosu','Ojo','Sani'])[1 + (g / 10) % 10],
  'customer' || g || '@samypay.test',
  '080' || lpad((10000000 + g)::text, 8, '0'),
  DATE '1960-01-01' + (random() * 15000)::int
FROM generate_series(1, 5000) AS g;

-- 8,000 accounts
INSERT INTO accounts (account_number, customer_id, branch_id, account_type, balance, status)
SELECT
  '30' || lpad(g::text, 8, '0'),
  1 + g % 5000,
  1 + g % 8,
  CASE WHEN g % 3 = 0 THEN 'CURRENT' ELSE 'SAVINGS' END,
  round((random() * 2000000)::numeric, 2),
  CASE WHEN g % 50 = 0 THEN 'FROZEN' ELSE 'ACTIVE' END
FROM generate_series(1, 8000) AS g;

-- 100,000 transactions
INSERT INTO transactions (type_id, from_account_id, to_account_id, amount, status, created_at)
SELECT
  tt.type_id,
  CASE WHEN s.type_name IN ('WITHDRAWAL', 'TRANSFER') THEN s.acc1 END,
  CASE WHEN s.type_name = 'DEPOSIT' THEN s.acc1
       WHEN s.type_name = 'TRANSFER' THEN ((s.acc1 - 1 + s.shift) % 8000) + 1 END,
  s.amount,
  CASE WHEN s.r < 0.92 THEN 'SUCCESS' WHEN s.r < 0.97 THEN 'FAILED' ELSE 'REVERSED' END,
  s.created_at
FROM (
  SELECT
    (ARRAY['DEPOSIT','WITHDRAWAL','TRANSFER','TRANSFER'])[1 + (random() * 3)::int] AS type_name,
    1 + (random() * 7999)::int AS acc1,
    1 + (random() * 7998)::int AS shift,
    round((100 + random() * 499900)::numeric, 2) AS amount,
    random() AS r,
    now() - random() * interval '365 days' AS created_at
  FROM generate_series(1, 100000)
) AS s
JOIN transaction_types tt ON tt.type_name = s.type_name;

-- Refresh the database's statistics so it plans queries properly
ANALYZE;