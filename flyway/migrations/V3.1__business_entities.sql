DO
$$
    BEGIN
        CREATE TYPE product_status_type AS ENUM ('available', 'discontinued', 'out_of_stock');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE worker_type AS ENUM ('manager', 'operator', 'courier');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

DO
$$
    BEGIN
        CREATE TYPE discount_type AS ENUM ('percentage', 'fixed');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

CREATE TABLE IF NOT EXISTS Product
(
    product_id             SERIAL PRIMARY KEY,
    product_subcategory_id INT                 NOT NULL REFERENCES ProductSubcategory (product_subcategory_id),
    store_id               INT                 NOT NULL REFERENCES Store (store_id),
    name                   VARCHAR(255)        NOT NULL,
    list_price             FLOAT               NOT NULL,
    average_rating         FLOAT DEFAULT 0.0,
    brand                  VARCHAR(255),
    status                 product_status_type NOT NULL
);

CREATE TABLE IF NOT EXISTS Discount
(
    discount_id   SERIAL PRIMARY KEY,
    name          VARCHAR(255)  NOT NULL,
    type          discount_type NOT NULL,
    value         FLOAT         NOT NULL,
    start_date    DATE          NOT NULL,
    end_date      DATE          NOT NULL,
    applicable_to VARCHAR(20)   NOT NULL CHECK (applicable_to IN ('product', 'category')),
    product_id    INT REFERENCES Product (product_id),
    category_id   INT REFERENCES ProductCategory (product_category_id),
    CHECK (
        (applicable_to = 'product' AND product_id IS NOT NULL AND category_id IS NULL) OR
        (applicable_to = 'category' AND category_id IS NOT NULL AND product_id IS NULL)
        )
);

CREATE TABLE IF NOT EXISTS PickUpPointWorker
(
    worker_id        SERIAL PRIMARY KEY,
    pick_up_point_id INT          NOT NULL REFERENCES PickUpPoint (pick_up_point_id),
    full_name        VARCHAR(255) NOT NULL,
    phone            VARCHAR(50)  NOT NULL,
    email            VARCHAR(255) NOT NULL,
    hire_date        DATE         NOT NULL,
    birth_date       DATE         NOT NULL,
    worker_type      worker_type  NOT NULL,
    salary           FLOAT        NOT NULL
);

CREATE TABLE IF NOT EXISTS WarehouseInventory
(
    inventory_id      SERIAL PRIMARY KEY,
    product_id        INT       NOT NULL REFERENCES Product (product_id),
    warehouse_id      INT       NOT NULL REFERENCES Warehouse (warehouse_id),
    quantity          INT       NOT NULL CHECK (quantity >= 0),
    reserved_quantity INT       NOT NULL CHECK (reserved_quantity >= 0),
    unit_price        FLOAT     NOT NULL,
    last_updated      TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS ProductQuestion
(
    product_question_id SERIAL PRIMARY KEY,
    product_id          INT  NOT NULL REFERENCES Product (product_id),
    question            TEXT NOT NULL,
    answer              TEXT
);

CREATE TABLE IF NOT EXISTS WorkingShift
(
    shift_id   SERIAL PRIMARY KEY,
    worker_id  INT       NOT NULL REFERENCES PickUpPointWorker (worker_id),
    start_time TIMESTAMP NOT NULL,
    end_time   TIMESTAMP NOT NULL
);

INSERT INTO Product (product_subcategory_id, store_id, name, list_price, average_rating, brand, status)
SELECT ps.product_subcategory_id,
       s.store_id,
       'Product ' || s.store_id,
       CAST(random_between(50, 1000) AS FLOAT),
       cast((random() * 5) as FLOAT),
       'Brand from' || s.name,
       ('{available,discontinued,out_of_stock}'::product_status_type[])[random_between(1, 3)]
FROM ProductSubcategory ps,
     Store s, generate_series(1, 5)
LIMIT ${SEED_COUNT} * 2;

INSERT INTO Discount (name, type, value, start_date, end_date, applicable_to,
                      product_id, category_id)
SELECT 'Discount ',
       ('{percentage, fixed}'::discount_type[])[random_between(1, 2)],
       (random() * 50)::DECIMAL(10, 2),
       CURRENT_DATE,
       CURRENT_DATE + (random_between(7, 30))::INT,
       'product',
       (ARRAY(SELECT product_id FROM Product ORDER BY random() LIMIT 10))[random_between(1, 10)],
       NULL
FROM generate_series(1, ${SEED_COUNT});

INSERT INTO PickUpPointWorker (pick_up_point_id, full_name, phone, email, hire_date, birth_date, worker_type, salary)
SELECT ppp.pick_up_point_id,
       faker.name(),
       faker.unique_phone_number(),
       faker.unique_email(),
       faker.date_this_year()::date,
       faker.date_of_birth()::date,
       ('{manager,operator,courier}'::worker_type[])[random_between(1, 3)],
       round(random_between(20000, 80000)::numeric, 2)
FROM (Select pick_up_point_id FROM PickUpPoint) ppp,
     (SELECT * FROM generate_series(1, 3)) g
LIMIT ${SEED_COUNT};

INSERT INTO WarehouseInventory (product_id, warehouse_id, quantity, reserved_quantity, unit_price, last_updated)
SELECT pr.product_id,
       wh.warehouse_id,
       random_between(0, 1000),
       random_between(0, 100),
       cast(random_between(50, 1000) as FLOAT),
       now()
FROM (SELECT * from Product order by random()) pr,
     (SELECT * from Warehouse order by random()) wh
LIMIT ${SEED_COUNT};

INSERT INTO ProductQuestion (product_id, question, answer)
SELECT p.product_id,
       faker.sentence(),
       CASE WHEN random() > 0.3 THEN faker.paragraph() END
FROM (SELECT product_id FROM Product ORDER BY random() LIMIT ${SEED_COUNT} / 3) p;

INSERT INTO WorkingShift (worker_id, start_time, end_time)
SELECT w.worker_id,
       (CURRENT_DATE + (random_between(8, 11) || ':00')::time),
       (CURRENT_DATE + (random_between(16, 20) || ':00')::time)
FROM (SELECT worker_id FROM PickUpPointWorker ORDER BY random() LIMIT ${SEED_COUNT} / 2) w;
