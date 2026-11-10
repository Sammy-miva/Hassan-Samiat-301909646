// SamyPay MongoDB sample data (simulated). Safe to run again: it clears the collections first.
db.customers.drop();
db.transactions.drop();

db.customers.insertMany([
  {
    customerId: 1, firstName: "Mariam", lastName: "Adamu",
    email: "mariam.adamu@samypay.test", phone: "08011111111",
    dateOfBirth: new Date("1990-05-14"), createdAt: new Date("2025-01-10"),
    accounts: [
      { accountNumber: "4000000001", accountType: "SAVINGS", branch: { name: "Ikeja Branch", city: "Lagos" }, balance: NumberDecimal("250000.00"), status: "ACTIVE", openedAt: new Date("2025-01-10") },
      { accountNumber: "4000000002", accountType: "CURRENT", branch: { name: "Ikeja Branch", city: "Lagos" }, balance: NumberDecimal("80000.00"), status: "ACTIVE", openedAt: new Date("2025-03-02") }
    ]
  },
  {
    customerId: 2, firstName: "Ade", lastName: "Bello",
    email: "ade.bello@samypay.test", phone: "08022222222",
    dateOfBirth: new Date("1985-11-23"), createdAt: new Date("2025-02-15"),
    accounts: [
      { accountNumber: "4000000003", accountType: "SAVINGS", branch: { name: "Wuse Branch", city: "Abuja" }, balance: NumberDecimal("500000.00"), status: "ACTIVE", openedAt: new Date("2025-02-15") }
    ]
  },
  {
    customerId: 3, firstName: "Ngozi", lastName: "Okafor",
    email: "ngozi.okafor@samypay.test", phone: "08033333333",
    dateOfBirth: new Date("1995-07-08"), createdAt: new Date("2025-04-20"),
    accounts: [
      { accountNumber: "4000000004", accountType: "SAVINGS", branch: { name: "Port Harcourt Branch", city: "Port Harcourt" }, balance: NumberDecimal("120000.00"), status: "ACTIVE", openedAt: new Date("2025-04-20") },
      { accountNumber: "4000000005", accountType: "CURRENT", branch: { name: "Port Harcourt Branch", city: "Port Harcourt" }, balance: NumberDecimal("45000.00"), status: "FROZEN", openedAt: new Date("2025-05-11") }
    ]
  },
  {
    customerId: 4, firstName: "Ibrahim", lastName: "Musa",
    email: "ibrahim.musa@samypay.test", phone: "08044444444",
    dateOfBirth: new Date("1978-01-30"), createdAt: new Date("2025-06-01"),
    accounts: [
      { accountNumber: "4000000006", accountType: "CURRENT", branch: { name: "Kano Branch", city: "Kano" }, balance: NumberDecimal("900000.00"), status: "ACTIVE", openedAt: new Date("2025-06-01") }
    ]
  },
  {
    customerId: 5, firstName: "Fatima", lastName: "Yusuf",
    email: "fatima.yusuf@samypay.test", phone: "08055555555",
    dateOfBirth: new Date("1999-09-17"), createdAt: new Date("2025-07-09"),
    accounts: [
      { accountNumber: "4000000007", accountType: "SAVINGS", branch: { name: "Ibadan Branch", city: "Ibadan" }, balance: NumberDecimal("30000.00"), status: "ACTIVE", openedAt: new Date("2025-07-09") },
      { accountNumber: "4000000008", accountType: "SAVINGS", branch: { name: "Enugu Branch", city: "Enugu" }, balance: NumberDecimal("65000.00"), status: "CLOSED", openedAt: new Date("2025-08-21") }
    ]
  }
]);

// Generate 200 sample transactions between the accounts above
const accountNumbers = ["4000000001","4000000002","4000000003","4000000004","4000000005","4000000006","4000000007","4000000008"];
const types = ["DEPOSIT", "WITHDRAWAL", "TRANSFER", "TRANSFER"];
const pick = () => accountNumbers[Math.floor(Math.random() * accountNumbers.length)];
const docs = [];
for (let i = 1; i <= 200; i++) {
  const type = types[Math.floor(Math.random() * types.length)];
  const a1 = pick();
  let a2 = pick();
  while (type === "TRANSFER" && a2 === a1) { a2 = pick(); }
  docs.push({
    transactionId: i,
    type: type,
    fromAccount: type === "DEPOSIT" ? null : a1,
    toAccount: type === "WITHDRAWAL" ? null : (type === "DEPOSIT" ? a1 : a2),
    amount: NumberDecimal((Math.floor(Math.random() * 500000) + 100) + ".00"),
    status: Math.random() < 0.92 ? "SUCCESS" : "FAILED",
    createdAt: new Date(Date.now() - Math.floor(Math.random() * 365 * 24 * 3600 * 1000))
  });
}
db.transactions.insertMany(docs);

// Indexes
db.customers.createIndex({ email: 1 }, { unique: true });
db.customers.createIndex({ "accounts.accountNumber": 1 });
db.transactions.createIndex({ fromAccount: 1, createdAt: -1 });
db.transactions.createIndex({ toAccount: 1, createdAt: -1 });

print("customers: " + db.customers.countDocuments());
print("transactions: " + db.transactions.countDocuments());