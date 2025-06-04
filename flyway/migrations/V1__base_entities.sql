CREATE OR REPLACE FUNCTION random_between(low INT, high INT)
    RETURNS INT AS
$$
BEGIN
    RETURN floor(random() * (high - low + 1) + low);
END;
$$ language 'plpgsql' STRICT;


DO
$$
    BEGIN
        CREATE TYPE payment_method_type AS ENUM ('bank_card', 'e_wallet', 'cash_on_delivery');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE payment_status_type AS ENUM ('pending', 'completed', 'failed');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE day_of_week_type AS ENUM ('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;


CREATE TABLE IF NOT EXISTS admin
(
    admin_id SERIAL PRIMARY KEY,
    login    VARCHAR(255) NOT NULL,
    password VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS customer
(
    customer_id       SERIAL PRIMARY KEY,
    is_banned         BOOLEAN             NOT NULL DEFAULT false,
    email             VARCHAR(255) UNIQUE NOT NULL,
    phone             VARCHAR(50) UNIQUE  NOT NULL,
    password          VARCHAR(100)        NOT NULL,
    registration_date DATE                NOT NULL,
    name              VARCHAR(255)        NOT NULL,
    birth_date        DATE                NOT NULL
);

CREATE TABLE IF NOT EXISTS address
(
    address_id   SERIAL PRIMARY KEY,
    street       VARCHAR(255) NOT NULL,
    house_number VARCHAR(10)  NOT NULL,
    building     VARCHAR(10),
    apartment    VARCHAR(10),
    city         VARCHAR(100) NOT NULL,
    region       VARCHAR(100),
    postal_code  VARCHAR(10)  NOT NULL
);

CREATE TABLE IF NOT EXISTS seller
(
    seller_id  SERIAL PRIMARY KEY,
    is_banned  BOOLEAN             NOT NULL DEFAULT false,
    full_name  VARCHAR(255)        NOT NULL,
    phone      VARCHAR(50) UNIQUE  NOT NULL,
    email      VARCHAR(255) UNIQUE NOT NULL,
    password   VARCHAR(100)        NOT NULL,
    hire_date  DATE                NOT NULL,
    birth_date DATE                NOT NULL
);

CREATE TABLE IF NOT EXISTS productCategory
(
    product_category_id SERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS promocode
(
    code                VARCHAR(20) PRIMARY KEY,
    discount_amount     FLOAT   NOT NULL,
    minimal_order_price FLOAT   NOT NULL,
    is_available        BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS payment
(
    payment_id     SERIAL PRIMARY KEY,
    payment_method payment_method_type NOT NULL,
    amount         FLOAT               NOT NULL,
    status         payment_status_type NOT NULL,
    created_at     TIMESTAMP           NOT NULL
);

CREATE TYPE work_hours AS
(
    opens_at  TIME,
    closes_at TIME
);

CREATE TABLE IF NOT EXISTS pickupPointSchedule
(
    schedule_id  SERIAL PRIMARY KEY,
    weekly_hours work_hours[7] NOT NULL
);

DO
$$
    BEGIN
        IF '${APP_ENV}' = 'dev' THEN
            EXECUTE '
INSERT INTO admin (login, password)
SELECT faker.unique_user_name(),
       faker.password()
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO customer (is_banned,
                      email,
                      phone,
                      password,
                      registration_date,
                      name,
                      birth_date)
SELECT false,
       faker.unique_email(),
       faker.unique_phone_number(),
       faker.password(),
       faker.date_this_year()::date,
       faker.name(),
       faker.date_of_birth()::date
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO Address (street, house_number, building, apartment, city, region, postal_code)
SELECT faker.street_name(),
       faker.building_number(),
       random_between(1, 200)::varchar,
       random_between(1, 200)::varchar,
       faker.city(),
       faker.state(),
       random_between(1, 10000000)::varchar
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO seller (is_banned, full_name, phone, email, password, hire_date, birth_date)
SELECT false,
       faker.name(),
       faker.unique_phone_number(),
       faker.unique_email(),
       faker.password(),
       faker.date_this_year()::date,
       faker.date_of_birth()::date
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO productCategory (name)
SELECT faker.unique_name()
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO promocode (code, discount_amount, minimal_order_price, is_available)
SELECT faker.unique_password(),
       random_between(10, 1000),
       random_between(1000, 3000),
       true
FROM generate_series(1, ${SEED_COUNT} / 3);

INSERT INTO payment (payment_method, amount, status, created_at)
SELECT (ARRAY [''bank_card'', ''e_wallet'', ''cash_on_delivery''])[random_between(1, 3)]::payment_method_type,
       0,
       (ARRAY [''pending'', ''completed'', ''failed''])[random_between(1, 3)]::payment_status_type,
       NOW() - (random_between(1, 365) || '' days'')::interval
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO pickupPointSchedule (weekly_hours)
SELECT ARRAY[
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME),
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME),
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME),
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME),
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME),
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME),
           ROW(((random_between(0, 3) + 8)::varchar || '':00'')::TIME, ((random_between(0, 4) + 16)::varchar || '':00'')::TIME)]
           ::work_hours[]
FROM generate_series(1, ${SEED_COUNT});
';
        END IF;
    END
$$;
