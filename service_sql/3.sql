SELECT
    w.name AS warehouse,
    COUNT(wi.product_id) AS distinct_products,
    SUM(wi.quantity) AS total_items,
    SUM(wi.reserved_quantity) AS reserved_items
FROM warehouseInventory wi
         JOIN warehouse w using (warehouse_id)
         JOIN address a using (address_id)
GROUP BY w.name
HAVING SUM(wi.quantity) > 0;
