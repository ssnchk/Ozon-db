# M3203_VlasovAA

# Проектирование баз данных

# Предметная область: OZON (маркетплейс)

# Функциональные требования

1. **Регистрация и авторизация пользователей:**

    - Система должна предоставлять возможность регистрации новых пользователей (покупателей и продавцов) через email или
      номер телефона.

    - Система должна обеспечивать авторизацию зарегистрированных пользователей.

    - Система должна поддерживать восстановление пароля в случае его утери.

2. **Управление профилем пользователя:**

    - Покупатели должны иметь возможность редактировать свои личные данные (имя, адрес, телефон, email).

    - Продавцы должны иметь возможность добавлять и редактировать информацию о своем магазине (название, описание,
      контакты).

3. **Поиск и фильтрация товаров:**

    - Система должна предоставлять возможность поиска товаров по ключевым словам, категория, подкатегориям какой-либо
      категории, брендам и другим параметрам.

    - Пользователи должны иметь возможность фильтровать товары по цене, рейтингу, наличию, доставке и другим критериям.

    - Должны существовать категории и подкатегории, которые должны наследоваться от какой-либо категории

4. **Просмотр карточки товара:**

    - Для каждого товара должна быть доступна детальная информация: название, описание, цена, скидка, отзывы, рейтинг,
      наличие на складе.

    - Пользователи должны иметь возможность оставлять отзывы и оценки для товаров.

    - Пользователи могут задавать вопросы по товарам. Эти вопросы и ответы на них могут просматривать другие
      пользователи в карточке товаров.

5. **Управление корзиной и оформление заказа:**

    - Пользователи должны иметь возможность добавлять товары в корзину, изменять количество товаров и удалять их из
      корзины.

    - Система должна предоставлять возможность оформления заказа с выбором способа оплаты и доставки.

    - Среди выборов способов оплаты должны быть карты/наличные

    - Среди выборов способов доставки должны быть ПВЗ/доставка курьером
   
    - Пользователи должны иметь возможность отслеживать статус заказа.

    - Кроме корзины пользователь может лайкнуть товар

    - Пользователь имеет возможность вернуть товар
6. **Оплата товаров:**

    - Система должна поддерживать различные способы оплаты: банковские карты, электронные кошельки, оплата при
      получении.

7. **Доставка товаров:**

    - Система должна предоставлять выбор способов доставки: курьерская доставка, самовывоз в пункт выдачи заказов.

    - Пользователи должны иметь возможность отслеживать статус доставки.

8. **Управление заказами для продавцов:**

    - Продавцы должны иметь возможность добавлять, редактировать и удалять товары в своем магазине.

    - Продавцы должны видеть список заказов, их статусы и контактные данные покупателей.

9. **Система уведомлений:**

    - Пользователи должны получать уведомления о статусе заказа, акциях и новых поступлениях через email, SMS или
      push-уведомления.

10. **Администрирование системы:**

    - Администратор должен иметь возможность управлять пользователями, продавцами, товарами, заказами и настройками
      системы.

    - Администратор должен иметь возможность забанить продавца/пользователя

    - Администратор должен иметь доступ к аналитике: продажи, популярные товары, активность пользователей

11. **Система учета и хранения данных о заказе**

    - Для ПВЗ должны вестись часы работы, учет расходов и доходов

    - Должен вестись учет рабочих в ПВЗ и доставщиков 

    - Для доставщиков следует хранить их расписание, их заказы с указанными маршрутами доставки

12. **Система скидок и акций:**

    - Система должна поддерживать создание скидок, акций и промокодов для товаров.

    - Пользователи должны иметь возможность применять промокоды, действующие на все товары (на всю корзину).

13. **Рекомендации и персонализация:**

    - Система должна предлагать персонализированные рекомендации товаров на основе истории покупок и просмотров
      пользователя.

# ERD

```plantuml
@startuml
entity Admin{
  * admin_id : int
  login : varchar(255)
  password : varchar(20)
}

entity Customer {
    * customer_id : int
    --
    is_banned : boolean
    email : varchar(255)
    phone : varchar(20)
    password : varchar(100)
    registration_date : date
    name : varchar(255)
    birth_date : date
}

entity Address {
  * address_id : int
  --
  street : varchar(255)
  house_number : varchar(10)
  building : varchar(10)
  apartment : varchar(10)
  city : varchar(100)
  region : varchar(100)
  postal_code : varchar(10)
}

entity CustomerAddresses{
  customer_id : int <<FK>>
  address_id : int <<FK>>
}

Address ||--|| CustomerAddresses
Customer ||--o{CustomerAddresses

entity Seller {
    * seller_id : int
    --
    is_banned : boolean
    full_name : varchar(255)
  phone : varchar(20)
  email : varchar(255)
  hire_date : date
  birth_date : date
}

entity Store {
    * store_id : int
    seller_id : int <<FK>>
    --
    is_banned : boolean
    name : varchar(255)
    description : string
    contact_phone_number : varchar(20)
    contact_mail : varchar(255)
}

Seller ||--o{ Store

entity ProductSubcategory {
    * product_subcategory_id : int
    product_category_id : <<FK>>
    --
    name : varchar(255)
}

entity ProductCategory {
    * product_category_id : int
    --
    name : varchar(255)
}

ProductSubcategory }o--|| ProductCategory

entity Product {
    * product_id : int
    product_subcategory_id : int <<FK>>
    store_id : int <<FK>>
    --
    name : varchar(255)
    list_price : float
    average_rating : float
    brand : varchar(255)
    status : enum ['available', 'discontinued', 'out_of_stock']
}

ProductSubcategory ||--o{ Product
Store ||--o{ Product

entity OrderHeader {
    * order_id : int
    customer_id : int <<FK>>
    delivery_address_id : int <<FK>>
    promocode : varchar(20) <<FK>>
    payment_id : int <<FK>>
    --
    total_sum : float
    status : enum ['new', 'processing', 'issued'] 
    created_at : date
    delivery_type : enum ['pickup', 'delivery']
}

entity Payment {
    * payment_id : int
    --
    payment_method : enum ['bank_card', 'e_wallet', 'cash_on_delivery']
    amount : float
    status : enum ['pending', 'completed', 'failed']
    created_at : datetime
}

OrderHeader ||--||Payment
Address ||--o{OrderHeader

entity OrderDetail {
    * order_detail_id : int
    order_id : int <<FK>>
    product_id : int <<FK>>
    --
    status : enum ['processing', 'shipped', 'delivered', 'issued']
    amount : int
    is_returned boolean
    is_issued boolean
    date_of_issue date
}

OrderDetail }o--|| OrderHeader
OrderHeader }o--|| Customer
OrderDetail }o--|| Product

entity ProductReview {
    * product_review_id : int
    product_id : int <<FK>>
    order_detail_id : int <<FK>>
    --
    rating : float
    description : string
}

ProductReview }o--|| Product
OrderDetail ||--|| ProductReview

entity ProductQuestion {
    * product_question_id : int
    product_id : int <<FK>>
    --
    question : string
    answer : string
}

Product ||--o{ ProductQuestion

entity WishList{
  customer_id : int <<FK>>
  product_id : int <<FK>>
}

Customer ||--o{WishList
Product ||--o{WishList

entity Promocode{
  * code : varchar(20)
  --
  discount_amount : float
  minimal_order_price : float
  is_available : boolean
}

OrderHeader }o--|| Promocode

entity UsedPromocodes{
  promocode : varchar(20) <<FK>>
  customer_id : int <<FK>>
}

UsedPromocodes }o--||Customer
UsedPromocodes }o--||Promocode

entity Discount {
  * discount_id : int
  name : varchar(255)
  type : enum ['percentage', 'fixed']
  value : float
  start_date : date
  end_date : date
  applicable_to : enum ['product', 'category']
  product_id : int <<FK>>  # NULL, если applicable_to != 'product'
  category_id : int <<FK>> # NULL, если applicable_to != 'category'
}
Product ||--o{ Discount
ProductCategory ||--o{ Discount

entity PickUpPoint{
  * pick_up_point_id : int
  address_id : int <<FK>>
  schedule_id : int <<FK>>
  --
  contact_phone : varchar(20)
  closed_for_maintenance : boolean
}

entity PickupPointInventory {
    * inventory_id : int
    pickup_point_id : int <<FK>>
    order_detail_id : int <<FK>>
    --
    status : enum ['awaiting_pickup', 'picked_up']
    arrival_date : datetime
    pickup_untill : date
}

PickUpPoint ||--o{PickupPointInventory
PickupPointInventory ||--||OrderDetail

entity PickUpPointTransaction {
    * transaction_id : int
    pick_up_point_id : int <<FK>>
    --
    source : enum ['order_commission', 'other', 'rent', 'utilities', 'salaries', 'maintenance', 'other']
    amount : float
    description : text
    received_at : datetime
}


PickUpPointTransaction }o--||PickUpPoint


entity PickupPointSchedule {
    * schedule_id : int
    --
    day_of_week : enum ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
    opens_at : time
    closes_at : time 
}

PickUpPoint ||--||PickupPointSchedule
PickUpPoint ||--|| Address

entity WorkingShift{
  * shift_id : int
  worker_id : int <<FK>>
  --
  start_time : datetime
  end_time : datetime
}

entity PickUpPointWorker{
  * worker_id : int
  pick_up_point_id : int <<FK>>
  employee_info_id : int <<FK>>
  --
  full_name : varchar(255)
  phone : varchar(20)
  email : varchar(255)
  hire_date : date
  birth_date : date
  worker_type : enum ['manager', 'operator', 'courier']
  salary : float
}

WorkingShift }o--||PickUpPointWorker
PickUpPoint ||--o{PickUpPointWorker

entity Delivery{
  * delivery_id : int
  order_header_id : int <<FK>>
  shift_id : int <<FK>>
  --
  since_time : datetime
  untill_time : datetime
}

Delivery ||--||OrderHeader

Delivery ||--||WorkingShift

entity Warehouse {
    * warehouse_id : int
    address_id : int <<FK>>
    --
    name : varchar(255)
    contact_phone : varchar(20)
}

Warehouse ||--||Address

entity WarehouseInventory {
    * inventory_id : int
    product_id : int <<FK>>
    warehouse_id : int <<FK>>
    --
    quantity : int
    reserved_quantity : int
    unit_price : float
    last_updated : datetime
}

WarehouseInventory }o--||Warehouse
WarehouseInventory }o--||Product

entity Notification {
  * notification_id : int
  user_id : int <<FK>>
  --
  destionation_type : ['customer', 'seller', 'worker']
  type : enum ['email', 'sms', 'push']
  message : text
  is_read : boolean
  created_at : datetime
}
Customer ||--o{ Notification
Seller ||--o{ Notification
PickUpPointWorker ||--o{Notification

@enduml
```
