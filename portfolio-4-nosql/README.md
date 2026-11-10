# Portfolio 4: NoSQL

# Portfolio 4: NoSQL and Advanced Data Models (MongoDB)

## Purpose
This portfolio models the SamyPay bank in a NoSQL database to compare it with
the relational design from Portfolios 1 to 3 which are sql. I chose MongoDB, a document
database, which stores data as flexible JSON-like documents instead of rows in
tables.

## Environment
- Database: MongoDB 8.0 (Community Edition), a single local server
- Where it runs: GitHub Codespaces (Linux terminal)
- Shell used: `mongosh`
- Database name: `samypay_nosql`

## Step 1: Installation
MongoDB is not in the default Linux package list, so I added MongoDB's package
source, installed `mongodb-org`, and started the server by hand with:
```
mongod --fork --logpath /tmp/mongod.log --dbpath ~/mongo-data
```
The data folder `~/mongo-data` sits outside the repository so the database
files are not uploaded to GitHub. I tested the install by inserting and reading
back a small document with `mongosh`, then deleted it.

## Step 2: The data model
In PostgreSQL, one customer's information is spread across the `customers`,
`accounts` and `branches` tables. But In MongoDB, data that is read together is kept
together in one document.

| MongoDB collection | What one document holds | Replaces these tables |
|---|---|---|
| `customers` | A customer with their accounts nested inside, each account carrying its branch name and city | `customers`, `accounts`, `branches` |
| `transactions` | One transaction, pointing to its accounts by account number | `transactions`, `transaction_types` |

The `audit_log` table was not modelled in this first version.

### Example of a customer document (shortened)
```
{
  customerId: 1, firstName: "Mariam", lastName: "Adamu",
  email: "mariam.adamu@samypay.test",
  accounts: [
    { accountNumber: "4000000001", accountType: "SAVINGS",
      branch: { name: "Ikeja Branch", city: "Lagos" },
      balance: Decimal128("250000.00"), status: "ACTIVE" },
    { accountNumber: "4000000002", ... }
  ]
}
```

### Design decisions
1. **Accounts are embedded in the customer.** A customer has only a few
   accounts, and a screen showing a customer normally needs them all, so one
   read returns everything with no join.
2. **Transactions are a separate collection.** An account can collect
   thousands of transactions, and one MongoDB document is limited to 16 MB.
   Embedding transactions would make the customer document grow without limit.
3. **The branch name and city are copied into each account.** This avoids a
   join, but the same branch details are now stored many times. This is the
   opposite of the normalisation in Portfolio 1, and it is a deliberate
   trade-off. Renaming a branch would mean updating every account that
   contains it.
4. **Balances and amounts use `Decimal128`.** Ordinary numbers are
   floating-point and can create rounding errors with money.

## Step 3: Implementation
The script `samypayseed.js` loads simulated data: 5 customers (8 accounts in total)
and 200 transactions between those accounts. It also creates four indexes:
a unique index on `customers.email`, an index on `accounts.accountNumber`, and
indexes on `transactions` for `(fromAccount, createdAt)` and
`(toAccount, createdAt)`. It clears the collections first, so it can be run again.

Command used:
```
mongosh samypay_nosql --quiet --file portfolio-4-nosql/samypayseed.js
```
Output:
```
customers: 5
transactions: 200
```

![Seed script output](mongo-seed-counts.png)

## Step 4: Queries
The queries are in `samypayqueries.js` and the results are in `queries-output.txt`.

| Query | What it does | Result |
|---|---|---|
| 1 | Find a customer by email | Returned Ade Bello |
| 2 | Active accounts with balance above 100,000 | 4 accounts: 4000000001, 4000000003, 4000000004 and 4000000006. The frozen and closed accounts were excluded. |
| 3 | Latest 5 transactions for account 4000000001 | 5 transactions, newest first, from 6 November 2026 back to 28 September 2026 |
| 4 | Monthly totals of successful transactions | 13 months, from 2025-11 to 2026-11, adding up to 178 successful transactions |
| 5 | Total balance per city | Kano 900,000, Abuja 500,000, Lagos 330,000, Port Harcourt 165,000, Enugu 65,000, Ibadan 30,000 |
| 6 | Index check for account 4000000001 | 16 documents examined, 16 returned, using the index |

### How the queries differ from SQL
- Queries 2 and 5 use `$unwind`, which splits each customer's nested accounts
  into separate rows so they can be filtered or grouped. In SQL, the accounts
  would be reached with a join. In MongoDB, embedding removes the join for
  simple reads, but queries across accounts need this extra step.
- Query 4 is the same question as the monthly totals query in Portfolio 2, but
  written as an aggregation pipeline, a series of steps (filter, group, sort).
- Query 3 uses `$or` to find transactions where the account is the sender or
  the receiver, like the OR condition in Portfolio 2.

## Step 5: Index evidence
For Query 6, the winning plan was an index scan (`IXSCAN`) on
`fromAccount_1_createdAt_-1`, followed by a fetch. It examined 16 documents and
returned 16, so it read only the documents it needed. Without the index,
MongoDB would have examined all 200 documents (a collection scan). Because the
index is ordered by date, no separate sort step was needed. The collection is
small, so the time difference is tiny, and I did not measure it.

## Step 6: Is MongoDB suitable for SamyPay?

### Where it fits well
- **Reading a customer profile:** one read returns the customer and all their
  accounts, with no joins.
- **Flexible structure:** new fields, for example identity verification data or
  device information, can be added to some documents without changing a table
  for everyone.
- **Large transaction history:** the transactions collection can grow very
  large, and MongoDB can spread it across servers (sharding), which Portfolio 5
  looks at.
- **Read-heavy features:** a mobile app showing balances and recent activity.

### Where PostgreSQL is the better choice
- **Moving money safely:** a transfer changes two balances and records a
  transaction. In PostgreSQL I built this as one all-or-nothing function in
  Portfolio 3. MongoDB supports multi-document transactions only on a replica
  set, and my local server is a single standalone server, so I did not test them.
- **Rules enforced by the database:** in PostgreSQL, rules such as
  `balance >= 0` and foreign keys are checked automatically. In MongoDB, these
  would have to be added as validation rules or enforced in the application.
- **Reports across data:** auditing and reporting that join several kinds of
  data are simpler in SQL.

### Comparison with the SamyPay business rules
| Rule | PostgreSQL (Portfolios 1 to 3) | MongoDB (this portfolio) |
|---|---|---|
| 1: unique email | UNIQUE constraint | Unique index on `customers.email` |
| 3: unique account number | UNIQUE constraint | Not enforced. The index on `accounts.accountNumber` is not unique. |
| 4: balance never below zero | CHECK constraint | Not enforced. No validation rule was created. |
| 5: amount above zero | CHECK constraint | Not enforced. No validation rule was created. |
| 6, 7, 8: safe transfers | `transfer_funds()` function | Not implemented. It would need application code and a replica set. |
| 10, 11: no deletes, audit log | Triggers | Not implemented |

### Conclusion
MongoDB suits SamyPay's customer profiles and large, read-heavy transaction
history, but the core of banking, which is moving money correctly and enforcing
rules, is better handled in PostgreSQL. A sensible design would use both:
PostgreSQL as the system of record for balances and transfers, and MongoDB for
profile screens and history. I did not build or test this combined design.

## Limitations
- The MongoDB data is simulated and separate from the PostgreSQL data, so
  balances do not match any transactions.
- The random transactions ignore account status. For example, transaction 159 in
  the Query 3 output sends money to account 4000000008, which is CLOSED, and
  some transactions involve frozen accounts.
- Only the validation and uniqueness listed in the comparison table were
  implemented.
- The data is small (5 customers, 200 transactions), so the index evidence shows
  how the index is used, not a real speed gain.
- Running `samypayseed.js` again generates new random transactions, so results such as
  Query 3 would differ.

## Files in this folder
- `samypayseed.js`: creates the collections, sample data and indexes
- `samypayqueries.js`: the six queries
- `queries-output.txt`: the output of the queries
- `README.md`: this document