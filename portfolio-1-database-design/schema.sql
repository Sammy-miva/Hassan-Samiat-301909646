CREATE TABLE branches (
    branch_id   SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city        VARCHAR(100) NOT NULL
);

CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    date_of_birth DATE NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
    account_id     SERIAL PRIMARY KEY,
    account_number VARCHAR(10) NOT NULL UNIQUE,
    customer_id    INT NOT NULL REFERENCES customers(customer_id),
    branch_id      INT NOT NULL REFERENCES branches(branch_id),
    account_type   VARCHAR(20) NOT NULL CHECK (account_type IN ('SAVINGS','CURRENT')),
    balance        NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    opened_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_types (
    type_id   SERIAL PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE transactions (
    transaction_id  SERIAL PRIMARY KEY,
    type_id         INT NOT NULL REFERENCES transaction_types(type_id),
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id   INT REFERENCES accounts(account_id),
    amount          NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED','REVERSED')),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_log (
    audit_id    SERIAL PRIMARY KEY,
    account_id  INT NOT NULL REFERENCES accounts(account_id),
    old_balance NUMERIC(15,2) NOT NULL,
    new_balance NUMERIC(15,2) NOT NULL,
    changed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
