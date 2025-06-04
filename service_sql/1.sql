SELECT
    pc.name AS category,
    ps.name AS subcategory,
    COUNT(od.order_detail_id) AS orders_count,
    SUM(od.amount * p.list_price) AS total_revenue,
    AVG(pr.rating) AS avg_rating
FROM orderDetail od
         JOIN product p using (product_id)
         JOIN productSubcategory ps using (product_subcategory_id)
         JOIN productCategory pc using (product_category_id)
         LEFT JOIN productReview pr using (product_id)
WHERE od.status = 'delivered' AND p.status = 'available'
GROUP BY pc.name, ps.name
ORDER BY total_revenue DESC
LIMIT 100;

