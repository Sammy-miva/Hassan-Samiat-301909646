# Portfolio 2: Query Optimisation
## Purpose
This portfolio shows how SQL queries run on the SamyPay database, how I
checked their performance, and how indexes can make them faster. It uses the
same SamyPay database designed in Portfolio 1.

## Environment
- Database: PostgreSQL 16
- Where it runs: GitHub Codespaces (Linux terminal)
- Database name: `samypay`
- Tool used to run SQL: `psql`

## Step 1: Loading sample data
A query only shows a clear speed difference when there is a lot of data to
search through. I wrote a script, `samypaydata.sql`, that fills the database with
simulated data. No real customer information is used.

| Table | Rows loaded |
|---|---|
| branches | 8 |
| customers | 5,000 |
| accounts | 8,000 |
| transactions | 100,000 |
This much data is needed so a speed differnce shows up

The script also adds the four transaction types: DEPOSIT, WITHDRAWAL,
TRANSFER and REVERSAL. Amounts, dates and statuses are generated randomly,
and each transaction follows the SamyPay rules from Portfolio 1, for example
a deposit has a receiving account but no sending account.

### How I ran it
```
psql -d samypay -f portfolio-2-query-optimisation/samypaydata.sql
```

### Checking the result
I counted the rows in each table to confirm the data loaded correctly:
```
SELECT (SELECT count(*) FROM branches) AS branches,
       (SELECT count(*) FROM customers) AS customers,
       (SELECT count(*) FROM accounts) AS accounts,
       (SELECT count(*) FROM transactions) AS transactions;
```

![Row counts after loading data](row-counts.png)

The counts match the numbers in the table above.

### Problem I met
one issue i had when running it for thefirst time, the script ran
twice and the transactions table showed 200,000 rows. I emptied the tables
with TRUNCATE and ran the script once to get the correct counts.

## Step 2: Queries
| Query | What it answers | Tables used |
|---|---|---|
| 1 | Transaction history of one account | transactions, transaction_types |
| 2 | Monthly totals of successful transactions | transactions |
| 3 | Top 10 customers by total balance | customers, accounts |
| 4 | Failed transactions per branch (last 90 days) | transactions, accounts, branches |
| 5 | Largest transfers with sender and receiver | transactions, transaction_types, accounts |

The queries are in `samypayqueries.sql` and the results are in `query-results.txt`.

## Step 3: Execution plans (before indexing)
I ran each query with `EXPLAIN ANALYZE` before creating any indexes. The
full output is in `explain-before.txt`, and the script is `explain-before.sql`.

When a query is ran , PostgreSQL does two things:

Planning: it decides how to find the answer, for example which table to read first, whether to use an index, and how to join tables. This is the Planning Time line.
Execution: it carries out that plan and returns the rows. This is the Execution Time line, and it’s the number you’re comparing before and after indexing.

EXPLAIN ANALYZE shows both the plan and the real timings. The plan is a tree of steps. Read it from the most indented line inward, because the deepest steps run first and feed their results upward. Each step shows:

Part	Meaning
Seq Scan	Reads every row of a table
Filter	The condition applied to each row it reads
Rows Removed by Filter	Rows read and then thrown away
actual time=a..b	When the step started and finished, in milliseconds
rows=	How many rows the step produced
Hash Join	Matches rows from two tables using a lookup table in memory
Sort, Aggregate	Ordering the result, or grouping and counting it

| Query | Main scan type | Execution time (before) |
|---|---|---|
| 1: Transaction history for one account | Seq Scan on transactions | 6.944 ms |
| 4: Failed transactions per branch | Seq Scan on transactions | 9.689 ms |
| 5: Largest transfers | Seq Scan on transactions | 22.412 ms |

#### Seq Scan on transactions
means the database read the whole table, all 100,000 rows.
Rows Removed by Filter: 90121 means it threw away 90,121 of them to keep the 9,879 with amount > 450000.
The rest of the plan (the Hash Joins and the Sort) is cheap by comparison. The sequential scan took about 13.9 of the 22.4 ms.
Seq Scan on accounts and on transaction_types are fine. Those tables are small, so an index wouldn’t help there.

## Step 4: Indexes and optimisation

An index works like the index at the back of a textbook. Instead of reading every page, the database jumps straight to the right rows. We’ll add four indexes on transactions, matching what your queries filter on
Query 1 switched from Seq Scan to a Bitmap or Index scan on the account columns, and drop noticeably.
Query 4 should use the status, created_at index and improve.
Query 5 may or may not change. About 10% of rows pass its filter, so the database may decide reading the whole table is cheaper.
Times are in milliseconds because the data is small, so differences look modest. A real bank table would have far more rows and a bigger gap. Timings also vary slightly between runs
Four indexes were created on the transactions table (see `samypayindexes.sql`).

| Query | Scan before | Scan after | Time before | Time after |
|---|---|---|---|---|
| 1 | Seq Scan | Bitmap Index Scan (two account indexes) | 6.944 ms | 0.360 ms |
| 4 | Seq Scan | Bitmap Index Scan (status, created_at) | 9.689 ms | 5.063 ms |
| 5 | Seq Scan | Index Scan Backward (amount) | 22.412 ms | 0.268 ms |


## Step 5: Performance analysis

### 5.1 How the test was done
- Database: PostgreSQL 16 in GitHub Codespaces, database `samypay`.
- Data: simulated, with 8 branches, 5,000 customers, 8,000 accounts and
  100,000 transactions.
- Method: each query was run with `EXPLAIN ANALYZE`, once before and once
  after creating four indexes on the `transactions` table. Each script was
  run twice and the second run was recorded, so the first run could warm up
  the cache.
- Evidence: `explain-before.txt`, `explain-after.txt`, `samypayindexes.sql`,
  `plan-summary-before.txt` and `plan-summary-after.txt`.

### 5.2 Results
| Query | Scan before | Scan after | Time before | Time after | Faster by | Time saved |
|---|---|---|---|---|---|---|
| 1: One account's history | Seq Scan | Bitmap Index Scan (two account indexes) | 6.944 ms | 0.360 ms | about 19 times | 94.8% |
| 4: Failed transactions per branch | Seq Scan | Bitmap Index Scan (status, created_at) | 9.689 ms | 5.063 ms | about 1.9 times | 47.7% |
| 5: Largest transfers | Seq Scan | Index Scan Backward (amount) | 22.412 ms | 0.268 ms | about 84 times | 98.8% |


### 5.3 Query 1: transaction history for one account
Before indexing, the database had no quick way to find account 500's
transactions, so it read all 100,000 rows and kept only the matching ones.
After indexing, it used the `from_account_id` index and the `to_account_id`
index separately and combined the results (a BitmapOr). Each index found 9
rows, and the database fetched only those 18 rows from the table. Because the
work now depends on the number of matching rows, not the size of the table,
the query stays fast as the table grows. This matters for SamyPay because a
customer statement is one of the most frequent operations in a bank.

### 5.4 Query 4: failed transactions per branch
The `(status, created_at)` index let the database find the 1,179 failed
transactions from the last 90 days directly, instead of testing every row.
The query still improved by only about 1.9 times. The index only speeds up
the step that finds the rows. The remaining work is unchanged: joining the
rows to `accounts` and `branches`, then grouping and counting them. The join
also uses `COALESCE(from_account_id, to_account_id)`, which cannot use the
account indexes in the same way as a plain column match. 

### 5.5 Query 5: largest transfers
Before indexing, the database read all 100,000 rows, removed 90,121 rows
that failed the `amount > 450000` filter, and sorted the remaining 9,879 rows
to find the top 20. It also built a hash table of all 8,000 accounts twice to
do the joins. After indexing, the database read the `amount` index from the
largest value downwards (Index Scan Backward) and stopped after about 26
rows, because the query only needs 20. It then looked up the 20 sending and
20 receiving accounts through their primary keys instead of scanning the whole
accounts table. This was the biggest improvement because the index removed
both the sort and most of the reading.

### 5.6 Why the improvements differ
| Query | What the index removed | What was left to do | Improvement |
|---|---|---|---|
| 1 | Reading the whole table | Fetch 18 rows | Large |
| 4 | Reading the whole table | Join and group about 1,179 rows | Moderate |
| 5 | Reading the table and the sort | Fetch 26 rows and 40 account lookups | Very large |

The size of the improvement depends on how much of the query's work the index
can replace. Indexes help most when a query needs a small number of rows
(Query 1) or only the top few rows in sorted order (Query 5). They help less
when many rows still have to be joined and grouped afterwards (Query 4).

### 5.7 Costs of indexing
Indexes are not free:
- - **Storage:** each index takes disk space. The four indexes on the
  transactions table use 880 kB, 880 kB, 3128 kB and 3072 kB, about 7960 kB
  (roughly 7.8 MB) in total.
- **Slower writes:** every new transaction must also update all four indexes,
  so inserts, updates and deletes do more work. SamyPay records transactions
  constantly, so the number of indexes should be limited to those that real
  queries need.
- **Planner choice:** an index is not always used. If a query needs a large
  share of the table, PostgreSQL may prefer a sequential scan. In Query 5,
  about 10% of rows passed the amount filter on its own, so I expected little
  benefit. It still improved a lot because of the `ORDER BY ... LIMIT`, which
  shows that the planner's decision depends on the whole query, not only on
  the filter.

### 5.8 Limitations
- The data is small and simulated, so all times are only a few milliseconds.
  A real bank table with millions of rows would show larger gaps.
- Timings vary slightly between runs, so the percentages are approximate. I
  recorded one measurement per query.
- Balances and transactions were generated randomly, so they do not match
  each other, and some frozen accounts have transactions. This does not affect
  the query speed tests, but it means the data is not a realistic record of
  banking activity.

### 5.9 Conclusion
Indexes on the columns used for filtering and sorting made the three queries
faster, with improvements from about 1.9 times to about 84 times. The best
results came when the index matched what the query asked for. 