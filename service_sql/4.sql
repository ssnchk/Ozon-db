SELECT
    p.name AS product_name,
    pc.name AS category,
    s.name AS store,
    COUNT(od.order_detail_id) AS orders_count,
    AVG(pr.rating) AS avg_rating,
    SUM(od.amount) AS total_sold
FROM product p
         JOIN productSubcategory ps using(product_subcategory_id)
         JOIN productCategory pc using(product_category_id)
         JOIN store s using(store_id)
         JOIN orderDetail od ON p.product_id = od.product_id
         LEFT JOIN productReview pr ON p.product_id = pr.product_id
WHERE od.status = 'delivered'::order_detail_status_type and p.status = 'available'::product_status_type
GROUP BY p.name, pc.name, s.name
ORDER BY total_sold DESC;


