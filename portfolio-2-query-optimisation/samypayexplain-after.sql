\echo '=== Query 1 plan (after indexing) ==='
EXPLAIN ANALYZE
SELECT t.transaction_id, tt.type_name, t.amount, t.status, t.created_at
FROM transactions t
JOIN transaction_types tt ON tt.type_id = t.type_id
WHERE t.from_account_id = 500 OR t.to_account_id = 500
ORDER BY t.created_at DESC;

\echo '=== Query 4 plan (after indexing) ==='
EXPLAIN ANALYZE
SELECT b.branch_name, count(*) AS failed_transactions
FROM transactions t
JOIN accounts a ON a.account_id = COALESCE(t.from_account_id, t.to_account_id)
JOIN branches b ON b.branch_id = a.branch_id
WHERE t.status = 'FAILED'
  AND t.created_at >= now() - interval '90 days'
GROUP BY b.branch_name
ORDER BY failed_transactions DESC;

\echo '=== Query 5 plan (after indexing) ==='
EXPLAIN ANALYZE
SELECT t.transaction_id, fa.account_number AS sender,
       ta.account_number AS receiver, t.amount, t.created_at
FROM transactions t
JOIN transaction_types tt ON tt.type_id = t.type_id
JOIN accounts fa ON fa.account_id = t.from_account_id
JOIN accounts ta ON ta.account_id = t.to_account_id
WHERE tt.type_name = 'TRANSFER' AND t.amount > 450000
ORDER BY t.amount DESC
LIMIT 20;