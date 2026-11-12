1. Selected organization -
I chose SamyPay, a simulated digital bank (a fintech), as the single case study for all five portfolios. Customers open savings or current accounts and can deposit, withdraw and transfer money. The users are customers, bank staff, administrators and auditors. All data are simulated and the tools used were PostgreSQL 16 and MongoDB 8.0, run in GitHub Codespaces (GitHub, n.d.).
2. Portfolio 1: Database design and modelling
I designed six related tables (branches, customers, accounts, transaction_types, transactions and audit_log) and ran the schema in PostgreSQL 16, where the table listing showed all six and the accounts structure showed every key and constraint. Every table has a primary key and foreign keys that link accounts to customers and branches. Eleven business rules are matched to database checks, and all tables meet 1NF, 2NF and 3NF, except that the account balance is stored deliberately for fast reads. Evidence is in the portfolio-1-database-design folder.
3. Portfolio 2: Query processing and optimization
Four indexes made the three slowest queries between about 1.9 and 84 times faster on 100,000 simulated transactions (with 8 branches, 5,000 customers and 8,000 accounts). I measured each query with EXPLAIN ANALYZE, which runs the statement and reports the real run time of each step (PostgreSQL Global Development Group, n.d.), before and after creating the indexes.
Query	Before	After	Plan after indexing
1: one account's history	6.944 ms	0.360 ms	Bitmap Index Scan on the two account indexes
4: failed transactions per branch	9.689 ms	5.063 ms	Bitmap Index Scan on (status, created_at)
5: largest transfers	22.412 ms	0.268 ms	Index Scan Backward on amount
The four indexes use 7,960 kB and slow down inserts and updates. The data is small and simulated and each time is a single run, so real gaps would be larger. Evidence is in the portfolio-2-query-optimisation folder.
4. Portfolio 3: Transactions and concurrency
Two withdrawals of 80,000 both succeeded on an account holding 100,000, and row locking and the SERIALIZABLE isolation level each stopped that.
On two demo accounts, a 30,000 transfer inside one transaction was committed (balances 70,000 and 80,000), and a 500,000 transfer that broke the balance CHECK rule was undone with ROLLBACK, restoring both balances.
With two terminals I then tested concurrent withdrawals from the same account, starting at PostgreSQL's default isolation level, Read Committed (PostgreSQL Global Development Group, n.d.):
Test	What happened	Final balance
Default level, no lock	Both sessions read 100,000 and both withdrew 80,000 (lost update)	20,000, with 160,000 approved
SELECT ... FOR UPDATE	The second session waited until the first finished, as row locks are designed to do (PostgreSQL Global Development Group, n.d.), then saw 20,000 and rolled back	20,000, one withdrawal
SERIALIZABLE	The second session failed with "could not serialize access due to concurrent update"	20,000, one withdrawal
I then built a transfer_funds() function that checks the amount, both account statuses and the sender's funds before changing any balance and records failures as FAILED, plus triggers that log every balance change and refuse deletes on transactions. 
5. Portfolio 4: NoSQL and advanced data models
MongoDB suits SamyPay's customer profiles and transaction history, but PostgreSQL is the better for moving money and enforcing rules.
I modelled SamyPay as documents in MongoDB 8.0. Each customer document contains their accounts, with the branch details copied in, so one read returns a customer and all their accounts with no join. Transactions are a separate collection because an account can collect thousands of them and a document is limited to 16 MB (MongoDB, Inc., n.d.). I loaded 5 customers (8 accounts) and 200 transactions, created four indexes and ran six queries, including aggregations for monthly totals and balance per city. The index check examined 16 documents instead of all 200.
Copying the branch details is a deliberate trade-off against normalization, since renaming a branch would mean updating every account that contains it. MongoDB did not enforce rules such as a non-negative balance or a unique account number in my version, and safe transfers would need a replica set. A sensible design would use PostgreSQL for balances and transfers and MongoDB for profile screens and history. Evidence is in the portfolio-4-nosql folder.
6. Portfolio 5: Distributed and cloud database exercise
A three-node MongoDB replica set copied every write to all nodes and elected a new primary automatically when I stopped the old one.
I started three nodes (ports 27018 to 27020) and joined them into the replica set samypayRS. In the replication test, an account written to the primary with majority acknowledgement was returned by all three nodes, and a write sent to a secondary was refused. In the failover test I stopped the primary (27018). Within the 20-second wait, the other nodes had elected 27019 as the new primary, a new account was written while one node was down, and after I restarted 27018 it held both accounts.
With three nodes, a majority is two, so the set can still elect a primary and acknowledge majority writes with one node down (MongoDB, Inc., n.d.). For a bank, MongoDB's default favours consistency over availability (the CAP idea): during a network split, only the side with a majority can elect a primary and accept writes (MongoDB, Inc., n.d.), which is safer than showing a wrong balance.
Sharding and cloud deployment are discussed but not built. For SamyPay, transactions would be sharded first on a hashed account number, because a ranged key that keeps increasing, such as a date, sends most new writes to one shard, which hashing avoids (MongoDB, Inc., n.d.). In production, each node would sit on a different server or availability zone, or use a managed service such as MongoDB Atlas.
Limitation: all three nodes ran on one Codespace, so this shows how replication and failover work but gives no protection against a machine failing, and only a single-node failure was tested. Evidence is in the portfolio-5-distributed-cloud folder.
7. Individual technical reflection
The biggest lesson was that a database design is only trustworthy once I have run it and seen it behave.
Design choices. I stored the account balance even though it could be calculated from transactions, so a CHECK rule can stop it going below zero and reads stay fast, and I added an audit trigger to keep it checkable. In MongoDB I embedded accounts in the customer but kept transactions separate, accepting that copying the branch name breaks normalization.
Challenges.
•	I was new to GitHub and Codespaces: commands pasted into the editor created stray files, and PostgreSQL and MongoDB stopped whenever the Codespace restarted.
•	My data script ran twice and gave 200,000 transactions instead of 100,000, so I now check row counts after every load.
•	The lost update in Portfolio 3 showed me that a CHECK constraint cannot catch a wrong balance that is still a valid number.
Lessons learned. Constraints, transactions and locks protect against different problems, indexes speed up reads but cost storage and slow writes, and MongoDB and PostgreSQL suit different parts of the same bank. Next time I would test more than one node failing, add a reversal procedure and use separate servers.
8. GitHub repository
All scripts, outputs, diagrams and READMEs are in my private repository: https://github.com/Sammy-miva/Hassan-Samiat-301909646 It has one folder per portfolio, from portfolio-1-database-design to portfolio-5-distributed-cloud.
9. AI Use Declaration
•	Tool: Claude (Anthropic).
•	Used for: explaining the assignment, guiding my GitHub and Codespaces setup, and drafting the design documents, SQL, JavaScript and shell scripts, some of the readme texts for proper explanation.
•	How I checked it: I ran every script in my own Codespace, compared each output with what was expected, and fixed the problems that came up, such as the data loading twice. I reviewed and read up on terminologies and edited the text so I can understand and  explain every part of the submitted work.

