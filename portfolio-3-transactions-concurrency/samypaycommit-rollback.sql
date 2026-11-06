\echo '=== Balances before ==='
SELECT account_number, balance FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

\echo '=== Demo 1: successful transfer of 30,000 (COMMIT) ==='
BEGIN;
UPDATE accounts SET balance = balance - 30000 WHERE account_number = '9000000001';
UPDATE accounts SET balance = balance + 30000 WHERE account_number = '9000000002';
INSERT INTO transactions (type_id, from_account_id, to_account_id, amount, status)
SELECT (SELECT type_id FROM transaction_types WHERE type_name = 'TRANSFER'),
       (SELECT account_id FROM accounts WHERE account_number = '9000000001'),
       (SELECT account_id FROM accounts WHERE account_number = '9000000002'),
       30000, 'SUCCESS';
COMMIT;

\echo '=== After COMMIT: expect 70000 and 80000 ==='
SELECT account_number, balance FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

\echo '=== Demo 2: transfer of 500,000 from an account holding 70,000 (fails, ROLLBACK) ==='
BEGIN;
UPDATE accounts SET balance = balance + 500000 WHERE account_number = '9000000002';
UPDATE accounts SET balance = balance - 500000 WHERE account_number = '9000000001';
ROLLBACK;

\echo '=== After failed transfer: expect 70000 and 80000 (unchanged) ==='
SELECT account_number, balance FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

\echo '=== Demo 3: manual ROLLBACK ==='
BEGIN;
UPDATE accounts SET balance = balance - 10000 WHERE account_number = '9000000001';
\echo 'Inside the transaction (expect 60000):'
SELECT account_number, balance FROM accounts WHERE account_number = '9000000001';
ROLLBACK;
\echo 'After ROLLBACK (expect 70000):'
SELECT account_number, balance FROM accounts WHERE account_number = '9000000001';