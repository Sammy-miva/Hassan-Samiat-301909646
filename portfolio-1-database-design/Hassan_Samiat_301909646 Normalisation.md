# SamyPay Normalization

Normalization means organizing data so that each fact is stored once. It is a structured and orderly  process of arranging and organizing data within a relational database to reduce data redundancy, eliminate data anomalies, and improve data integrity. It involves breaking down large, complex tables into smaller, well-structured tables and defining logical relationships between them based on functional dependencies.

## Starting point: one big table (unnormalized)
If SamyPay kept everything in a single table, it might look like this:
| transaction_id | account_numbers | customer_name | customer_email | branch_name | branch_city | type_name | amount |
|---|---|---|---|---|---|---|---|
| 1 | 0123456789, 0456789123 | Mariam Adamu | adamu@mail.com | Ikeja | Lagos | TRANSFER | 5000 |
| 2 | 0123456789, 0456789123 | Mariam Adamu | adamu@mail.com | Ikeja | Lagos | DEPOSIT | 20000 |

Problems with this table:
- Mariam’s name and email are repeated on every row.
- If Mariam changes her email, every row has to be changed.
- Two account numbers are squeezed into one cell which breaks the one-value-per-cell rule.
- A new customer can’t be saved until they make a transaction.
- Deleting a customer’s only transaction also deletes their details.

## First Normal Form (1NF): Atomic values which means no repeating groups or arrays per cell
Rule: every cell holds a single value, with no lists.
Fix: the account_numbers cell held two numbers. In SamyPay, each account should get its own row in the accounts table, so no cell holds more than one value.

## Second Normal Form (2NF): Meet 1NF requirement  + Remove partial dependencies i.e non-key attributes must depend on the entire primary key
Rule: a detail must depend on the full primary key, not just part of it.
Every SamyPay table has a single-column primary key, so 2NF is met automatically.

## Third Normal Form (3NF): details describe only the row they sit in
Rule: a detail must describe the row's own key, not another detail.
In the big table, customer_name, customer_email, branch_name and branch_city describe the customer and the branch, not the transaction.
Fix: 
- `customers` (name, email, phone, date of birth)
- `branches` (branch name, city)
- `accounts` (links a customer and a branch to an account number)
- `type_name` was moved to `transaction_types`, and `transactions` stores only `type_id`
- `accounts` stores only `customer_id`, not the customer's name or email
## Final result
The final tables are `branches`, `customers`, `accounts`, `transaction_types`,
`transactions` and `audit_log`. Each fact is stored in one place only:
- A customer's email is stored once, in `customers`.
- A branch name is stored once, in `branches`.
- A transaction type name is stored once, in `transaction_types`.

With this design, the problems above no longer happen:
- Changing an email means changing one row. 
- A customer can be saved before any transaction exists.
- Deleting a transaction does not remove the customer or the branch.

One deliberate exception is the balance column in the accounts table. The balance could be worked out by adding up all of an account’s transactions, but I stored it for two reasons.
1.	Checking a balance is 	much faster than calculating it from scratch every single time . Every time a user opens their app or swipes a card, the database has to scan, filter, and add up potentially thousands of past transactions to answer "How much money is in this account?" As transaction history grows, this gets slower and slower which makes checking balance stressful and slower.
2.	It lets us set a database rule that prevents an account from ever dropping below zero.

To keep it safe, every balance change is written to `audit_log`, so auditors can compare the stored balance with the transactions.


