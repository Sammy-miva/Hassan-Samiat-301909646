print("--- Query 1: Find a customer by email ---");
printjson(db.customers.findOne(
  { email: "ade.bello@samypay.test" },
  { _id: 0, firstName: 1, lastName: 1, email: 1 }
));

print("--- Query 2: Active accounts with balance above 100,000 ---");
db.customers.aggregate([
  { $unwind: "$accounts" },
  { $match: { "accounts.status": "ACTIVE", "accounts.balance": { $gt: NumberDecimal("100000") } } },
  { $project: { _id: 0,
      customer: { $concat: ["$firstName", " ", "$lastName"] },
      accountNumber: "$accounts.accountNumber",
      balance: "$accounts.balance" } }
]).forEach(d => printjson(d));

print("--- Query 3: Latest 5 transactions for account 4000000001 ---");
db.transactions.find({
  $or: [ { fromAccount: "4000000001" }, { toAccount: "4000000001" } ]
}).sort({ createdAt: -1 }).limit(5).forEach(d => printjson(d));

print("--- Query 4: Monthly totals of successful transactions ---");
db.transactions.aggregate([
  { $match: { status: "SUCCESS" } },
  { $group: {
      _id: { $dateToString: { format: "%Y-%m", date: "$createdAt" } },
      numberOfTransactions: { $sum: 1 },
      totalAmount: { $sum: "$amount" } } },
  { $sort: { _id: 1 } }
]).forEach(d => printjson(d));

print("--- Query 5: Total balance per city ---");
db.customers.aggregate([
  { $unwind: "$accounts" },
  { $group: {
      _id: "$accounts.branch.city",
      numberOfAccounts: { $sum: 1 },
      totalBalance: { $sum: "$accounts.balance" } } },
  { $sort: { totalBalance: -1 } }
]).forEach(d => printjson(d));

print("--- Query 6: Index check for account 4000000001 ---");
const plan = db.transactions.find({ fromAccount: "4000000001" })
  .sort({ createdAt: -1 }).explain("executionStats");
print("Documents examined: " + plan.executionStats.totalDocsExamined);
print("Documents returned: " + plan.executionStats.nReturned);
print("Winning plan: " + JSON.stringify(plan.queryPlanner.winningPlan));