#!/bin/bash
echo "=== 1. Write one account to the PRIMARY (port 27018) ==="
mongosh --port 27018 --quiet --eval '
db = db.getSiblingDB("samypay_rs");
db.accounts_demo.drop();
const r = db.accounts_demo.insertOne(
  { accountNumber: "5000000001", owner: "Demo Customer", balance: NumberDecimal("100000.00"), status: "ACTIVE" },
  { writeConcern: { w: "majority" } }
);
print("Insert acknowledged: " + r.acknowledged);
'

sleep 2

for port in 27018 27019 27020; do
  echo "=== Reading from the node on port $port ==="
  mongosh --port $port --quiet --eval '
  db.getMongo().setReadPref("secondaryPreferred");
  db = db.getSiblingDB("samypay_rs");
  print("Role: " + (db.hello().isWritablePrimary ? "PRIMARY" : "SECONDARY"));
  db.accounts_demo.find({}, { _id: 0 }).forEach(d => printjson(d));
  '
done

echo "=== Trying to WRITE to a SECONDARY (port 27019): should be refused ==="
mongosh --port 27019 --quiet --eval '
db = db.getSiblingDB("samypay_rs");
try {
  db.accounts_demo.insertOne({ accountNumber: "5000000002" });
  print("Unexpected: the write was accepted");
} catch (e) {
  print("Refused as expected: " + e.message);
}
'