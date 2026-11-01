# Portfolio 1: Database Design
# SamyPay: Case Study Description

## 1. About SamyPay
SamyPay is a simulated digital bank and payments company (a fintech). It lets
people open bank accounts on their phone, keep their money safe, and send or
receive money without visiting a branch. SamyPay also has a small number of
branches where customers can get in-person help.

## 2. Users and What They Do
Customers- Register, open accounts, deposit money, withdraw money, transfer to other accounts, and view their transaction history.
Staff / support agent- Help customers, check account details, freeze or unfreeze accounts, and look into failed transactions.
Administrators- Manage branches, set up account types, and control who has access to the system.
Auditors-Review transactions and balance records to confirm the money adds up and nothing was changed improperly.

## 3. Main Operations
1. Account Opening: a registered customer opens a savings or current account at a branch.
2. Deposit: money is added to an account.
3. Withdraw: money is taken out of an account.
4.Transfer funds: money moves from one SamyPay account to another.
5. Reverse a failed transaction: if a transfer goes wrong, the money is returned and the reversal is recorded.
6. View history: customers and staff can see past transactions for an account.
7. Audit balances auditors check that account balances match the recorded transactions.

## 4. Business Rules
A business rule is a condition the system must always follow. SamyPay's rules are:
1. Every customer must provide a unique email address, so no two customers share one.
2. Every account must belong to exactly one customer and one branch.
3. Every account must have a unique account number.
4. An account balance can never go below zero (no overdrafts).
5. Every transaction amount must be greater than zero.
6. Only active accounts can send or receive money. Frozen or closed accounts cannot.
7. A transfer must take money from one account and add the same amount to the other, or not happen at all. It can never be half-completed.
8. If a transaction fails, the account balances must stay exactly as they were.
9. Every transaction must be recorded with its type, amount, status, and date.
10. Reversed transactions must be marked as reversed. They are never deleted.
11. Every change to an account balance must be recorded in an audit log.

## 5. Scope
- Customer, account, branch, and transaction records
- Deposits, withdrawals, transfers, and reversals
- Transaction history and balance auditing

Not included:
- A mobile app or website screens (this project focuses only on the database)
- Real banking connections or real money
- Loans, cards, interest calculation, and international payments
- Real customer data (all data is simulated)
