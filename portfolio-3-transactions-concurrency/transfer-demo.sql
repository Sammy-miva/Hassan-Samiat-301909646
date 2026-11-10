\echo '=== Reset demo balances ==='
UPDATE accounts SET balance = 100000, status = 'ACTIVE' WHERE account_number = '9000000001';
UPDATE accounts SET balance = 50000,  status = 'ACTIVE' WHERE account_number = '9000000002';
SELECT account_number, balance, status FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

\echo '=== Test 1: valid transfer of 30,000 ==='
SELECT transfer_funds('9000000001', '9000000002', 30000);
SELECT account_number, balance FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

\echo '=== Test 2: transfer of 500,000 (insufficient funds) ==='
SELECT transfer_funds('9000000001', '9000000002', 500000);
SELECT account_number, balance FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

\echo '=== Test 3: receiver account is frozen ==='
UPDATE accounts SET status = 'FROZEN' WHERE account_number = '9000000002';
SELECT transfer_funds('9000000001', '9000000002', 1000);
UPDATE accounts SET status = 'ACTIVE' WHERE account_number = '9000000002';

\echo '=== Test 4: negative amount ==='
SELECT transfer_funds('9000000001', '9000000002', -50);

\echo '=== Recorded transactions for the sender (newest first) ==='
SELECT transaction_id, amount, status FROM transactions
WHERE from_account_id = (SELECT account_id FROM accounts WHERE account_number = '9000000001')
ORDER BY transaction_id DESC LIMIT 5;

\echo '=== Audit log for the demo accounts (newest first) ==='
SELECT a.account_number, l.old_balance, l.new_balance, l.changed_at
FROM audit_log l JOIN accounts a ON a.account_id = l.account_id
WHERE a.account_number IN ('9000000001', '9000000002')
ORDER BY l.audit_id DESC LIMIT 8;

\echo '=== Test 5: try to delete a transaction (should be refused) ==='
DELETE FROM transactions WHERE transaction_id = (SELECT max(transaction_id) FROM transactions);