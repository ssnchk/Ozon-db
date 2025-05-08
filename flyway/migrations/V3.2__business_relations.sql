DO
$$
    BEGIN
        CREATE TYPE order_status_type AS ENUM ('new', 'processing', 'issued');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE delivery_type_type AS ENUM ('pickup', 'delivery');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE order_detail_status_type AS ENUM ('processing', 'shipped', 'delivered', 'issued');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE inventory_status_type AS ENUM ('awaiting_pickup', 'picked_up');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE transaction_source_type AS ENUM (
            'order_commission',
            'other',
            'rent',
            'utilities',
            'salaries',
            'maintenance'
            );
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE destination_type_type AS ENUM ('customer', 'seller', 'worker');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE notification_type_type AS ENUM ('email', 'sms', 'push');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

CREATE TABLE IF NOT EXISTS OrderHeader
(
    order_id            SERIAL PRIMARY KEY,
    customer_id         INT                NOT NULL REFERENCES Customer (customer_id),
    delivery_address_id INT                NOT NULL REFERENCES Address (address_id),
    promocode           VARCHAR(20) REFERENCES Promocode (code),
    payment_id          INT                NOT NULL REFERENCES Payment (payment_id),
    total_sum           FLOAT              NOT NULL,
    status              order_status_type  NOT NULL,
    created_at          DATE               NOT NULL,
    delivery_type       delivery_type_type NOT NULL
);

CREATE TABLE IF NOT EXISTS OrderDetail
(
    order_detail_id SERIAL PRIMARY KEY,
    order_id        INT                      NOT NULL REFERENCES OrderHeader (order_id),
    product_id      INT                      NOT NULL REFERENCES Product (product_id),
    status          order_detail_status_type NOT NULL,
    amount          INT                      NOT NULL,
    is_returned     BOOLEAN                  NOT NULL DEFAULT false,
    is_issued       BOOLEAN                  NOT NULL DEFAULT false,
    date_of_issue   DATE
);

CREATE TABLE IF NOT EXISTS PickupPointInventory
(
    inventory_id    SERIAL PRIMARY KEY,
    pickup_point_id INT                   NOT NULL REFERENCES PickUpPoint (pick_up_point_id),
    order_detail_id INT                   NOT NULL REFERENCES OrderDetail (order_detail_id),
    status          inventory_status_type NOT NULL,
    arrival_date    TIMESTAMP             NOT NULL,
    pickup_untill   DATE                  NOT NULL
);

CREATE TABLE IF NOT EXISTS PickUpPointTransaction
(
    transaction_id   SERIAL PRIMARY KEY,
    pick_up_point_id INT                     NOT NULL REFERENCES PickUpPoint (pick_up_point_id),
    source           transaction_source_type NOT NULL,
    amount           FLOAT                   NOT NULL,
    description      TEXT,
    received_at      TIMESTAMP               NOT NULL
);

CREATE TABLE IF NOT EXISTS ProductReview
(
    product_review_id SERIAL PRIMARY KEY,
    product_id        INT   NOT NULL REFERENCES Product (product_id),
    order_detail_id   INT   NOT NULL REFERENCES OrderDetail (order_detail_id),
    rating            FLOAT NOT NULL CHECK (rating BETWEEN 0 AND 5),
    description       TEXT  NOT NULL
);

CREATE TABLE IF NOT EXISTS WishList
(
    customer_id INT NOT NULL REFERENCES Customer (customer_id),
    product_id  INT NOT NULL REFERENCES Product (product_id),
    PRIMARY KEY (customer_id, product_id)
);

CREATE TABLE IF NOT EXISTS Delivery
(
    delivery_id     SERIAL PRIMARY KEY,
    order_header_id INT       NOT NULL REFERENCES OrderHeader (order_id),
    shift_id        INT       NOT NULL REFERENCES WorkingShift (shift_id),
    since_time      TIMESTAMP NOT NULL,
    untill_time     TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS Notification
(
    notification_id  SERIAL PRIMARY KEY,
    user_id          INT                    NOT NULL,
    destination_type destination_type_type  NOT NULL,
    type             notification_type_type NOT NULL,
    message          TEXT                   NOT NULL,
    is_read          BOOLEAN                NOT NULL DEFAULT false,
    created_at       TIMESTAMP              NOT NULL
);

DO
$$
    BEGIN
        IF '${APP_ENV}' = 'dev' THEN
            EXECUTE '
INSERT INTO OrderHeader (customer_id, delivery_address_id, promocode, payment_id, total_sum, status, created_at,
                         delivery_type)
SELECT c.customer_id,
       (SELECT address_id FROM CustomerAddresses WHERE customer_id = c.customer_id ORDER BY random() LIMIT 1),
       NULL,
       (ARRAY(SELECT payment_id FROM Payment ORDER BY random() LIMIT ${SEED_COUNT}))[random_between(1, ${SEED_COUNT})],
       0,
       (''{new, processing, issued}''::order_status_type[])[random_between(1, 3)],
       faker.date_this_year()::date,
       (''{pickup, delivery}''::delivery_type_type[])[random_between(1, 2)]
FROM (SELECT customer_id FROM Customer ORDER BY random() LIMIT ${SEED_COUNT}) c;

INSERT INTO OrderDetail (order_id, product_id, status, amount, is_returned, is_issued, date_of_issue)
WITH order_products AS
         (SELECT o.order_id,
                 p.product_id,
                 p.list_price,
                 random_between(1, 5)                                                                           as amount,
                 (''{processing, shipped, delivered, issued}''::order_detail_status_type[])[random_between(1, 4)] as status
          FROM OrderHeader o
                   CROSS JOIN LATERAL (
              SELECT product_id, list_price
              FROM Product
              ORDER BY random()
              LIMIT random_between(1, 5)
              ) p)
SELECT order_id,
       product_id,
       status,
       amount,
       false                                                       as is_returned,
       status = ''issued''                                           as is_issued,
       CASE WHEN status = ''issued'' THEN faker.date_this_year()::date END as date_of_issue
FROM order_products;

UPDATE OrderHeader oh
SET total_sum = (SELECT SUM(od.amount * p.list_price)
                 FROM OrderDetail od
                          JOIN Product p ON od.product_id = p.product_id
                 WHERE od.order_id = oh.order_id);

UPDATE OrderHeader oh
SET promocode = (SELECT up.promocode
                 FROM UsedPromocodes up
                          JOIN Promocode p ON up.promocode = p.code
                 WHERE up.customer_id = oh.customer_id
                   AND p.is_available = true
                   AND p.minimal_order_price <= oh.total_sum
                 ORDER BY random()
                 LIMIT 1)
WHERE random() < 0.3;

UPDATE OrderHeader oh
SET total_sum = total_sum - (SELECT oh.total_sum * p.discount_amount / 100
                             FROM Promocode p
                             WHERE p.code = oh.promocode)
WHERE promocode IS NOT NULL;

UPDATE Payment p
SET amount = oh.total_sum
FROM OrderHeader oh
WHERE p.payment_id = oh.payment_id;

INSERT INTO PickupPointInventory (pickup_point_id, order_detail_id, status, arrival_date, pickup_untill)
SELECT (SELECT pick_up_point_id FROM PickUpPoint ORDER BY random() LIMIT 1),
       od.order_detail_id,
       (''{awaiting_pickup, picked_up}''::inventory_status_type[])[random_between(1, 2)],
       oh.created_at - INTERVAL ''1 day'',
       oh.created_at + INTERVAL ''7 days''
FROM OrderDetail od
         JOIN OrderHeader oh ON od.order_id = oh.order_id
WHERE oh.delivery_type = ''pickup''
LIMIT ${SEED_COUNT};

INSERT INTO PickUpPointTransaction (pick_up_point_id, source, amount, description, received_at)
SELECT (SELECT pick_up_point_id FROM PickUpPoint ORDER BY random() LIMIT 1),
       (''{order_commission, other, rent, utilities, salaries, maintenance}''::transaction_source_type[])[random_between(1, 6)],
       random_between(100, 10000),
       ''--'',
       NOW() - (random() * INTERVAL ''365 days'')
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO ProductReview (product_id, order_detail_id, rating, description)
SELECT
    od.product_id,
    od.order_detail_id,
    random_between(1, 5),
    faker.text()
FROM OrderDetail od
WHERE od.status = ''delivered'' OR od.status = ''issued''
ORDER BY random()
LIMIT ${SEED_COUNT};

INSERT INTO WishList (customer_id, product_id)
SELECT
    (ARRAY (SELECT customer_id FROM Customer ORDER BY random() LIMIT ${SEED_COUNT}))[random_between(1, ${SEED_COUNT})],
    (ARRAY(SELECT product_id FROM Product ORDER BY random() LIMIT ${SEED_COUNT}))[random_between(1, ${SEED_COUNT})]
FROM generate_series(1, ${SEED_COUNT})
ON CONFLICT DO NOTHING;

INSERT INTO Delivery (order_header_id, shift_id, since_time, untill_time)
SELECT
    oh.order_id,
    (ARRAY(SELECT shift_id FROM WorkingShift ORDER BY random() LIMIT ${SEED_COUNT} / 2))[random_between(1, ${SEED_COUNT} / 2)],
    oh.created_at + INTERVAL ''1 hour'',
    oh.created_at + INTERVAL ''3 hours''
FROM OrderHeader oh
WHERE oh.delivery_type = ''delivery''
LIMIT ${SEED_COUNT};

INSERT INTO Notification (user_id, destination_type, type, message, is_read, created_at)
SELECT c.customer_id,
       (''{customer,seller,worker}''::destination_type_type[])[1],
       (''{email,sms,push}''::notification_type_type[])[random_between(1, 3)],
       faker.sentence(),
       false,
       now()
FROM Customer c
LIMIT ${SEED_COUNT};';
        END IF;
    END
$$;
