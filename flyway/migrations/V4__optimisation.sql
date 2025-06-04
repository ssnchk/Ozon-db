CREATE INDEX IF NOT EXISTS idx_orderdetail_status ON orderDetail(status);
CREATE INDEX IF NOT EXISTS idx_product_review_product ON productReview(product_id);
CREATE INDEX IF NOT EXISTS idx_delivery_shift ON delivery(shift_id);
CREATE INDEX IF NOT EXISTS idx_workingshift_worker ON workingshift(worker_id);

CREATE MATERIALIZED VIEW pickUpPointsWeekSchedule AS
SELECT
    distinct
    p.pick_up_point_id,
    ps.weekly_hours[1].opens_at AS open_at_monday,
    ps.weekly_hours[1].closes_at AS close_at_monday,
    ps.weekly_hours[2].opens_at AS open_at_tuesday,
    ps.weekly_hours[2].closes_at AS close_at_tuesday,
    ps.weekly_hours[3].opens_at AS open_at_wednesday,
    ps.weekly_hours[3].closes_at AS close_at_wednesday,
    ps.weekly_hours[4].opens_at AS open_at_thursday,
    ps.weekly_hours[4].closes_at AS close_at_thursday,
    ps.weekly_hours[5].opens_at AS open_at_friday,
    ps.weekly_hours[5].closes_at AS close_at_friday,
    ps.weekly_hours[6].opens_at AS open_at_saturday,
    ps.weekly_hours[6].closes_at AS close_at_saturday,
    ps.weekly_hours[7].opens_at AS open_at_sunday,
    ps.weekly_hours[7].closes_at AS close_at_sunday
FROM pickuppoint p
         JOIN pickupPointSchedule ps USING (schedule_id);
