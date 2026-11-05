CREATE INDEX idx_transactions_from_account ON transactions (from_account_id);
CREATE INDEX idx_transactions_to_account ON transactions (to_account_id);
CREATE INDEX idx_transactions_status_created ON transactions (status, created_at);
CREATE INDEX idx_transactions_amount ON transactions (amount);
ANALYZE transactions;