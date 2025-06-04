CREATE TABLE IF NOT EXISTS customeraddresses
(
    customer_id INT REFERENCES customer (customer_id),
    address_id  INT REFERENCES address (address_id),
    PRIMARY KEY (customer_id, address_id)
);

CREATE TABLE IF NOT EXISTS store
(
    store_id             SERIAL PRIMARY KEY,
    seller_id            INT          NOT NULL REFERENCES seller (seller_id),
    is_banned            BOOLEAN      NOT NULL DEFAULT false,
    name                 VARCHAR(255) NOT NULL,
    description          TEXT,
    contact_phone_number VARCHAR(50),
    contact_mail         VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS productSubcategory
(
    product_subcategory_id SERIAL PRIMARY KEY,
    product_category_id    INT          NOT NULL REFERENCES productCategory (product_category_id),
    name                   VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS usedpromocodes
(
    promocode   VARCHAR(20) REFERENCES promocode (code),
    customer_id INT REFERENCES customer (customer_id),
    PRIMARY KEY (promocode, customer_id)
);

CREATE TABLE IF NOT EXISTS PickUpPoint
(
    pick_up_point_id       SERIAL PRIMARY KEY,
    address_id             INT         NOT NULL REFERENCES address (address_id),
    schedule_id            INT         NOT NULL REFERENCES pickupPointSchedule (schedule_id),
    contact_phone          VARCHAR(50) NOT NULL,
    closed_for_maintenance BOOLEAN     NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS warehouse
(
    warehouse_id  SERIAL PRIMARY KEY,
    address_id    INT          NOT NULL REFERENCES address (address_id),
    name          VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(50)  NOT NULL
);

DO
$$
    BEGIN
        IF '${APP_ENV}' = 'dev' THEN
            EXECUTE 'INSERT INTO customeraddresses (customer_id, address_id)
SELECT c.customer_id, a.address_id
FROM
    (SELECT customer_id, ROW_NUMBER() OVER () as rn FROM customer LIMIT ${SEED_COUNT}) c
        JOIN
    (SELECT address_id, ROW_NUMBER() OVER () as rn FROM address LIMIT ${SEED_COUNT}) a
    ON c.rn = a.rn;

INSERT INTO store (seller_id, is_banned, name, description, contact_phone_number, contact_mail)
SELECT s.seller_id,
       false,
       ''store of '' || s.full_name,
       faker.paragraph(2),
       faker.unique_phone_number(),
       faker.unique_email()
FROM seller s;

INSERT INTO productSubcategory (product_category_id, name)
SELECT
    pc.product_category_id,
    ''subcategory of '' || pc.product_category_id
FROM
    productCategory pc,
    generate_series(1, 3);

INSERT INTO usedpromocodes (promocode, customer_id)
SELECT
    (Array (SELECT code FROM promocode ORDER BY random() LIMIT ${SEED_COUNT} / 3))[random_between(1, ${SEED_COUNT} / 3)],
    (Array (SELECT customer_id FROM customer ORDER BY random() LIMIT ${SEED_COUNT}))[random_between(1, ${SEED_COUNT})]
FROM generate_series(1, ${SEED_COUNT} / 3)
ON CONFLICT DO NOTHING;

INSERT INTO PickUpPoint (address_id, schedule_id, contact_phone, closed_for_maintenance)
SELECT
    a.address_id,
    s.schedule_id,
    faker.phone_number(),
    false
FROM
    (SELECT schedule_id FROM pickupPointSchedule ORDER BY random() LIMIT ${SEED_COUNT} / 5) s,
    (SELECT address_id FROM address ORDER BY random() LIMIT ${SEED_COUNT} / 5) a
LIMIT ${SEED_COUNT}/5
ON CONFLICT DO NOTHING;

INSERT INTO warehouse (address_id, name, contact_phone)
SELECT
    a.address_id,
    ''OZON:'' || a.address_id,
    faker.phone_number()
FROM
    (SELECT address_id FROM address ORDER BY random() LIMIT ${SEED_COUNT} / 10) a;
';
        END IF;
    END
$$;

