-- Rule 11: log every balance change
CREATE OR REPLACE FUNCTION log_balance_change() RETURNS trigger AS $$
BEGIN
  IF NEW.balance IS DISTINCT FROM OLD.balance THEN
    INSERT INTO audit_log (account_id, old_balance, new_balance)
    VALUES (OLD.account_id, OLD.balance, NEW.balance);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_balance ON accounts;
CREATE TRIGGER trg_audit_balance
AFTER UPDATE OF balance ON accounts
FOR EACH ROW
EXECUTE FUNCTION log_balance_change();

-- Rule 10: transactions are never deleted
CREATE OR REPLACE FUNCTION block_transaction_delete() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'Transactions cannot be deleted. Mark them as REVERSED instead.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_no_delete_transactions ON transactions;
CREATE TRIGGER trg_no_delete_transactions
BEFORE DELETE ON transactions
FOR EACH ROW
EXECUTE FUNCTION block_transaction_delete();

-- Rules 5, 6, 7, 8: safe transfer
CREATE OR REPLACE FUNCTION transfer_funds(p_from VARCHAR, p_to VARCHAR, p_amount NUMERIC)
RETURNS TEXT AS $$
DECLARE
  v_from_id      INT;
  v_to_id        INT;
  v_from_balance NUMERIC;
  v_from_status  VARCHAR;
  v_to_status    VARCHAR;
  v_type_id      INT;
  v_reason       TEXT;
BEGIN
  -- Rule 5: amount must be above zero
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RETURN 'FAILED: amount must be above zero';
  END IF;

  IF p_from = p_to THEN
    RETURN 'FAILED: sender and receiver must be different';
  END IF;

  SELECT account_id INTO v_from_id FROM accounts WHERE account_number = p_from;
  SELECT account_id INTO v_to_id   FROM accounts WHERE account_number = p_to;
  IF v_from_id IS NULL OR v_to_id IS NULL THEN
    RETURN 'FAILED: account not found';
  END IF;

  -- Lock both accounts, lowest id first, so two transfers cannot deadlock
  PERFORM 1 FROM accounts
  WHERE account_id IN (v_from_id, v_to_id)
  ORDER BY account_id
  FOR UPDATE;

  SELECT balance, status INTO v_from_balance, v_from_status
  FROM accounts WHERE account_id = v_from_id;
  SELECT status INTO v_to_status FROM accounts WHERE account_id = v_to_id;
  SELECT type_id INTO v_type_id FROM transaction_types WHERE type_name = 'TRANSFER';

  -- Rule 6: both accounts must be active
  IF v_from_status <> 'ACTIVE' THEN
    v_reason := 'sender account is not active';
  ELSIF v_to_status <> 'ACTIVE' THEN
    v_reason := 'receiver account is not active';
  ELSIF v_from_balance < p_amount THEN
    v_reason := 'insufficient funds';
  END IF;

  -- Rule 8: a failed transfer changes no balance and is recorded as FAILED
  IF v_reason IS NOT NULL THEN
    INSERT INTO transactions (type_id, from_account_id, to_account_id, amount, status)
    VALUES (v_type_id, v_from_id, v_to_id, p_amount, 'FAILED');
    RETURN 'FAILED: ' || v_reason;
  END IF;

  -- Rule 7: debit, credit and record happen together or not at all
  UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_id;
  UPDATE accounts SET balance = balance + p_amount WHERE account_id = v_to_id;
  INSERT INTO transactions (type_id, from_account_id, to_account_id, amount, status)
  VALUES (v_type_id, v_from_id, v_to_id, p_amount, 'SUCCESS');

  RETURN 'SUCCESS';
END;
$$ LANGUAGE plpgsql;