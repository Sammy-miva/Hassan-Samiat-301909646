#!/bin/bash
URI="mongodb://localhost:27018,localhost:27019,localhost:27020/?replicaSet=samypayRS"
STATUS='rs.status().members.forEach(m => print(m.name + "  " + m.stateStr))'

echo "=== 1. Roles before the failure ==="
mongosh "$URI" --quiet --eval "$STATUS"

OLD=$(mongosh "$URI" --quiet --eval 'print(db.hello().primary)' | tail -1)
OLDPORT=${OLD##*:}
echo "Current primary: $OLD"

echo "=== 2. Stopping the primary on port $OLDPORT (simulating a server failure) ==="
mongosh --port $OLDPORT --quiet --eval 'db.getSiblingDB("admin").shutdownServer({ force: true })' > /dev/null 2>&1
echo "Primary stopped. Waiting 20 seconds for the other nodes to elect a new primary..."
sleep 20

echo "=== 3. Roles after the failure (the stopped node shows as not reachable) ==="
mongosh "$URI" --quiet --eval "$STATUS"

echo "=== 4. Writing a new account while one node is down ==="
mongosh "$URI" --quiet --eval '
db = db.getSiblingDB("samypay_rs");
const r = db.accounts_demo.insertOne(
  { accountNumber: "5000000002", owner: "Written During Failover", balance: NumberDecimal("55000.00"), status: "ACTIVE" },
  { writeConcern: { w: "majority" } }
);
print("Insert acknowledged: " + r.acknowledged);
'

echo "=== 5. Restarting the stopped node ==="
N=$((OLDPORT - 27017))
mongod --replSet samypayRS --port $OLDPORT --dbpath ~/rs/node$N --bind_ip localhost --fork --logpath /tmp/rs$N.log > /dev/null && echo "Node on port $OLDPORT restarted"
echo "Waiting 15 seconds for it to catch up..."
sleep 15

echo "=== 6. Roles after the restart ==="
mongosh "$URI" --quiet --eval "$STATUS"

echo "=== 7. Does the restarted node (port $OLDPORT) hold both accounts? ==="
mongosh --port $OLDPORT --quiet --eval '
db.getMongo().setReadPref("secondaryPreferred");
db = db.getSiblingDB("samypay_rs");
db.accounts_demo.find({}, { _id: 0 }).forEach(d => printjson(d));
'