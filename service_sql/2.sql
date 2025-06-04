SELECT
    worker_id
     , ppw.full_name
     , ppw.phone
     , ppw.email
     , ppw.worker_type
     , pp.pick_up_point_id
     , address.street
     , address.building
from delivery
         join workingshift ws using (shift_id)
         join pickuppointworker ppw using (worker_id)
         join pickuppoint pp using (pick_up_point_id)
         join address using (address_id)
WHERE pick_up_point_id = random_between(1, 9);

