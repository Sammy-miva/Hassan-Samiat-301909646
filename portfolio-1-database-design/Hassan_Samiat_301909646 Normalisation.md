# SamyPay Normalization

Normalization means organizing data so that each fact is stored once. It is a systematic process of organizing data within a relational database to reduce data redundancy, eliminate data anomalies, and improve data integrity. It involves breaking down large, complex tables into smaller, well-structured tables and defining logical relationships between them based on functional dependencies and It prevents repeated data and mistakes when records are updated

So my Starting point: one big table (unnormalized)
If SamyPay kept everything in a single table, it might look like this:
| transaction_id | account_numbers | customer_name | customer_email | branch_name | branch_city | type_name | amount |
|---|---|---|---|---|---|---|---|
| 1 | 0123456789, 0456789123 | Mariam Adamu | adamu@mail.com | Ikeja | Lagos | TRANSFER | 5000 |
| 2 | 0123456789, 0456789123 | Mariam Adamu | adamu@mail.com | Ikeja | Lagos | DEPOSIT | 20000 |

Problems with this table:
- Mariam’s name and email are repeated on every row.
- If Mariam changes her email, every row has to be changed.
- Two account numbers are squeezed into one cell which is not supposed to be.

## First Normal Form (1NF): Atomic values (no repeating groups or arrays per cell)
Rule: every cell holds a single value, with no lists.
Fix: the account_numbers cell held two numbers. In SamyPay, each account should get its own row in the account’s table, so no cell holds more than one value.

## Second Normal Form (2NF): Meet 1NF requirement  + Remove partial dependencies (non-key attributes must depend on the entire primary key) 
Rule: a detail must depend on the full primary key, not just part of it.
In the big table, `customer_name`, `customer_email`, `branch_name` and `branch_city` describe the account and its owner. They do not describe the transaction itself. They depend on only part of what identifies a row.
Fix: these details were moved out into their own tables:
`customers` (name, email, phone, date of birth)
 `branches` (branch name, city)
`accounts` (links a customer and a branch to an account number)

##Third Normal Form (3NF): details describe only the row they sit in
Rule: a detail must describe the row's own key, not another detail.
In the big table, `type_name` describes the transaction type, not the transaction. Also, in `accounts`, the customer's name would depend on `customer_id` rather than on the account.
Fix:
- `type_name` was moved to `transaction_types`, and `transactions` stores
  only `type_id`.
- `accounts` stores only `customer_id`, not the customer's name or email.

## Final result
The final tables are `branches`, `customers`, `accounts`, `transaction_types`,
`transactions` and `audit_log`. Each fact is stored in one place only:
- A customer's email is stored once, in `customers`.
- A branch name is stored once, in `branches`.
- A transaction type name is stored once, in `transaction_types`.

With this design, the three problems above no longer happen:
 Changing an email means changing one row. 
 A customer can be saved before any transaction exists.
 Deleting a transaction does not remove the customer or the branch.
Though there was one deliberate exception to the normalization which is storing the account balance directly in the accounts table, since if the sum of all past transactions can find the current balance. The balance field was kept for two key reasons-
1.	Checking a balance is instantaneous rather than having to calculate it from scratch every single time . Every time a user opens their app or swipes a card, the database has to scan, filter, and add up potentially thousands of past transactions to answer "How much money is in this account?" As transaction history grows, this gets slower and slower which makes checking balance stressful and not instant.
2.	It lets us set a database rule that prevents an account from ever dropping below zero.


