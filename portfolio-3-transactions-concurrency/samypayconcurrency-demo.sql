-- SamyPay concurrency demonstration (demo account 9000000001)
-- Type the lines one at a time. "Session A" lines go in Terminal A and
-- "Session B" lines go in Terminal B. Follow the order from top to bottom.

-- ===== PART 1: THE PROBLEM (lost update) =====
-- Setup, in either terminal:
UPDATE accounts SET balance = 100000 WHERE account_number = '9000000001';

-- Session A:
BEGIN;
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 100000

-- Session B:
BEGIN;
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 100000 too. Both sessions think an 80000 withdrawal is allowed.

-- Session A (withdraws 80000, so the new balance is 20000):
UPDATE accounts SET balance = 20000 WHERE account_number = '9000000001';
COMMIT;

-- Session B (also withdraws 80000, using the balance it read earlier):
UPDATE accounts SET balance = 20000 WHERE account_number = '9000000001';
COMMIT;

-- Check, in either terminal:
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 20000, but 160000 was withdrawn from an account holding 100000

-- ===== PART 2: THE FIX (row locking with FOR UPDATE) =====
-- Setup, in either terminal:
UPDATE accounts SET balance = 100000 WHERE account_number = '9000000001';

-- Session A:
BEGIN;
SELECT balance FROM accounts WHERE account_number = '9000000001' FOR UPDATE;
-- shows 100000 and locks the row

-- Session B:
BEGIN;
SELECT balance FROM accounts WHERE account_number = '9000000001' FOR UPDATE;
-- this WAITS. The terminal looks frozen, which is correct. Do not press anything.

-- Session A (withdraws 80000):
UPDATE accounts SET balance = balance - 80000 WHERE account_number = '9000000001';
COMMIT;
-- Terminal B now shows 20000 straight away, because the lock is released.

-- Session B (20000 is not enough for 80000, so it cancels):
ROLLBACK;

-- Check, in either terminal:
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 20000, and only one withdrawal happened

-- ===== PART 3: ISOLATION LEVEL (SERIALIZABLE) =====
-- Setup, in either terminal:
UPDATE accounts SET balance = 100000 WHERE account_number = '9000000001';

-- Session A:
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 100000

-- Session B:
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 100000

-- Session A:
UPDATE accounts SET balance = 20000 WHERE account_number = '9000000001';
COMMIT;

-- Session B:
UPDATE accounts SET balance = 20000 WHERE account_number = '9000000001';
-- ERROR: could not serialize access due to concurrent update
ROLLBACK;

-- Check, in either terminal:
SELECT balance FROM accounts WHERE account_number = '9000000001';
-- shows 20000, and the second withdrawal was refused