# Portfolio 3: Transactions and Concurrency

## Purpose
This portfolio shows how the SamyPay database keeps money movements safe
using transactions. A transaction groups several steps so that they either
all happen or none of them do. It uses the same `samypay` database designed
in Portfolio 1.

## Environment
- Database:I still made use of the  PostgreSQL 16 in GitHub Codespaces
- Database name: `samypay`
- Tool used to run SQL: `psql`

## Setup: demo accounts
To make the data accurate, i continued with the Portfolio 2 data, I created two demo customers and two demo accounts with known balances (`samypaysetup.sql`).

| Account number | Owner | Starting balance |
|---|---|---|
| 9000000001 | Demo Sender | 100,000 |
| 9000000002 | Demo Receiver | 50,000 |

## Demo 1: successful transfer (COMMIT)
I transferred 30,000 from the sender to the receiver inside one transaction.
It has three steps: debit the sender, credit the receiver, and record the
transfer in the `transactions` table. After `COMMIT`, the balance of the sender became 
70,000 while the receiver's own became  80,000, and the new transaction row was saved.

**What it shows:** all three steps were saved together (atomicity), and the
result stays saved after the commit (durability).

## Demo 2: failed transfer (ROLLBACK)
I tried to transfer 500,000 from an account holding only 70,000. The
receiver was credited first, and then the debit failed because of the rule
`CHECK (balance >= 0)` on the accounts table as the sender's balance was not enough for the transfer. PostgreSQL reported a check constraint error, and I ended the transaction with `ROLLBACK`. Both balances were back to 70,000 and 80,000.

**What it shows:** without a transaction, the receiver would have kept money
that never left the sender. The rollback undid the credit as well, so the
database stayed consistent. This supports business rules 7 and 8 from
Portfolio 1 (a transfer is complete or it does not happen, and a failed
transaction should leave balances unchanged).

## Demo 3: manual ROLLBACK
Inside a transaction I reduced the sender's balance by 10,000. Inside the
transaction the balance showed 60,000. After `ROLLBACK` it returned to
70,000.

**What it shows:** changes made inside a transaction are only temporary
until `COMMIT`, and `ROLLBACK` discards them.

## Results summary
| Step | Sender balance | Receiver balance |
|---|---|---|
| Before | 100,000 | 50,000 |
| After successful transfer (COMMIT) | 70,000 | 80,000 |
| After failed transfer (ROLLBACK) | 70,000 | 80,000 |
| Demo 3 inside the transaction | 60,000 | not changed |
| Demo 3 after ROLLBACK | 70,000 | 80,000 |

## Concurrency and isolation
[To be added: the concurrency problem, how it was controlled, and the
isolation level used.]

## Limitations
- The failed transfer in Demonstration 2 was caught by the CHECK rule on
  the balance. A real transfer procedure should also check that both accounts
  are ACTIVE and that the sender has enough money before changing anything.
- These demonstrations do not yet write to the `audit_log` table, so business
  rule 11 is not enforced yet.
- Running `samypaycommit-rollback.sql` again gives different starting balances,
  because the successful transfer is saved permanently each time.

## Files in this folder
- `samypaysetup.sql`: creates the demo customers and accounts
- `samypaygit add .
git commit -m "Add Portfolio 3 setup and commit-rollback demos"
git pushcommit-rollback.sql`: the three demonstrations
- `commit-rollback-output.txt`: the output of the demonstrations
- `README.md`: this document
- [more files will be listed as they are added]