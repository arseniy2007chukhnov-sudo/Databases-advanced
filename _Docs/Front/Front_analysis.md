# Front: описание таблиц и связей по направлениям анализа

> Источник: `table_info.csv`, `column_info.csv`, `relation_info.csv`. СУБД: Microsoft SQL Server, схема `dbo`.

- **Основные** таблицы группы — где хранятся факты; **связанные** — справочники и соседние сущности.
- Указаны только значимые для группы колонки. Типы и число строк — из CSV; **«Пример данных» — реальные значения из первых строк таблиц** (`sql/00_samples.sql`); `н/д` — колонка не попала на скриншоты, `(пусто)` — пустая строка.
- **FK** — объявлен в БД; **логическая** связь — по названию и типу колонок, FK не объявлен.

---

## 1. Анализ закупки продукции

**Основные таблицы:** `bm_StorageOperations`, `bm_JournalBarnetDocs`, `pricelist`  
**Связанные таблицы:** `bm_StorageOperationsType`, `bm_JournalTypeDocuments`, `bm_JournalType`, `vendors`, `product`, `category`, `size`, `storages`, `bm_Companies`, `bm_ReasonDebit`, `bm_Contracts`, `receiving`, `orders`

### 1.1 Связи между таблицами

| Дочерняя таблица.колонка | → | Родительская таблица.колонка | Тип связи |
|---|---|---|---|
| `bm_StorageOperations.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |
| `bm_StorageOperations.OperationID` | → | `bm_StorageOperationsType.ID` | FK |
| `bm_StorageOperations.ProductID` | → | `product.id` | FK |
| `bm_StorageOperations.StorageID` | → | `storages.id` | FK |
| `bm_StorageOperations.VendorID` | → | `vendors.id` | логическая (FK не объявлен) |
| `bm_StorageOperations.ContractID` | → | `bm_Contracts.ID` | логическая (FK не объявлен) |
| `bm_JournalBarnetDocs.DocumentTypeID` | → | `bm_JournalTypeDocuments.ID` | FK |
| `bm_JournalBarnetDocs.JournalID` | → | `bm_JournalType.ID` | FK |
| `bm_JournalBarnetDocs.CompanyID` | → | `bm_Companies.ID` | FK |
| `bm_JournalTypeDocuments.JournalID` | → | `bm_JournalType.ID` | FK |
| `pricelist.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |
| `pricelist.productid` | → | `product.id` | FK |
| `pricelist.vendorid` | → | `vendors.id` | логическая (FK не объявлен) |
| `product.CategoryID` | → | `category.id` | FK |
| `product.vendorid` | → | `vendors.id` | логическая (FK не объявлен) |
| `bm_Contracts.VendorID` | → | `vendors.id` | логическая (FK не объявлен) |

### 1.2 Описание таблиц

#### Основные таблицы

**`bm_StorageOperations`** — Складские движения (позиции складских документов): приход, расход, списание и т.д.  
*Строк: 1 031 198.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки движения (PK) | 4780421 |
| `DocumentID` | bigint | Документ-основание → bm_JournalBarnetDocs.ID | 388235 |
| `OperationID` | bigint | Вид операции → bm_StorageOperationsType.ID | 1 |
| `VendorID` | bigint | Поставщик → vendors.id (FK не объявлен) | 200 |
| `ContractID` | bigint | Договор → bm_Contracts.ID (таблица пуста) | 0 |
| `ProductID` | bigint | Товар/ингредиент → product.id | 4368 |
| `StorageID` | bigint | Склад → storages.id | 41 |
| `Price` | numeric | Цена | 323.00 |
| `PriceCost` | numeric | Себестоимость единицы | 0.00 |
| `Quantity` | numeric | Количество (в выборке 0.0000 при ненулевой сумме — см. также Count) | 0.0000 |
| `Amount` | numeric | Сумма строки | 892.77 |
| `DateAdd` | datetime | Дата добавления записи | 2020-11-15 14:15:30.183 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 1216 |
| `JournalID` | bigint | Журнал → bm_JournalType.ID | 1 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 1 |
| `CompanyID` | bigint | Организация → bm_Companies.ID | 6 |
| `DocumentNumber` | bigint | Номер документа | 1 |
| `Period` | datetime | Дата документа | 2013-07-23 10:00:00.000 |
| `Amount` | numeric | Сумма документа | 0.00 |
| `IsUse` | int | Признак «проведён/действует» | 1 |

**`pricelist`** — Прайс-листы поставщиков: цена товара у поставщика на дату действия.  
*Строк: 24 797.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код строки (PK) | 113681 |
| `DocumentID` | bigint | Документ-загрузка прайса → bm_JournalBarnetDocs.ID | 142417 |
| `productid` | bigint | Товар → product.id | 4544 |
| `vendorid` | bigint | Поставщик → vendors.id (в выборке NULL) | NULL |
| `basecost` | numeric | Базовая закупочная цена | 140.00 |
| `oldbasecost` | numeric | Предыдущая цена | NULL |
| `dateeff` | date | Дата вступления цены в силу (в выборке NULL) | NULL |
| `groupid` | int | Ценовая группа → pricegroup.pricegroupid | 2 |

#### Связанные таблицы

**`bm_StorageOperationsType`** — Справочник видов складских операций; Factor задаёт знак (+1 приход / −1 расход).  
*Строк: 5.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код вида операции (PK) | 1 |
| `Description` | varchar(max) | Наименование операции | Поступление (2 — Списание, −1; 3 — Инвентаризация, +1) |
| `Factor` | int | Множитель остатка: +1 или −1 | 1 |

**`bm_JournalTypeDocuments`** — Справочник типов документов внутри журнала.  
*Строк: 25.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код типа документа (PK) | 1 |
| `Description` | varchar(max) | Наименование типа | Ввод состава нового рецепта |
| `JournalID` | bigint | Журнал → bm_JournalType.ID | 1 |

**`bm_JournalType`** — Справочник журналов (склад, касса, прайс-листы…).  
*Строк: 6.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код журнала (PK) | 1 |
| `JournalName` | varchar(255) | Название журнала | Хозяйственный учет (2 — Финансовый, 3 — Складской) |

**`vendors`** — Справочник поставщиков.  
*Строк: 63.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 91 |
| `clientid` | varchar(24) | Наименование поставщика (фактически хранит имя, а не код) | Габур |
| `lastname` | varchar(100) | Фамилия/наименование (в выборке NULL — имя лежит в clientid) | NULL |
| `INN` | varchar(50) | ИНН | (пусто) |
| `IsUse` | int | Признак «используется» | 1 |

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 4337 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | 1204073 |
| `description` | varchar(255) | Наименование | Бананы |
| `vendorid` | bigint | Основной поставщик → vendors.id (FK не объявлен) | 107 |
| `CategoryID` | bigint | Категория → category.id | н/д |
| `purchcost` | numeric | Закупочная цена | NULL |
| `lastreceived` | datetime | Дата последнего прихода | NULL |

**`category`** — Справочник категорий номенклатуры (дерево).  
*Строк: 158.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 147 |
| `description` | varchar(255) | Наименование | Меню доставка |
| `ParentID` | int | Родительская категория | 0 |

**`size`** — Справочник единиц/порций.  
*Строк: 78.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `description` | varchar(255) | Наименование | порция |

**`storages`** — Склады (в БД — одна запись).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код склада (PK) | 41 |
| `description` | varchar(255) | Наименование склада | Склад |
| `CompanyID` | int | Организация → bm_Companies.ID (FK не объявлен) | 6 |

**`bm_Companies`** — Организации (юрлица).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 6 |
| `ShortName` | varchar(255) | Краткое наименование | Пиzzбург |
| `INN` | varchar(50) | ИНН | 380122679974 |

**`bm_ReasonDebit`** — Справочник причин списания (иерархия).  
*Строк: 47.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код причины (PK) | 1 |
| `ParentID` | bigint | Родительская причина | 0 |
| `Description` | varchar(255) | Наименование причины | Порча продукта |

**`bm_Contracts`** — Договоры с поставщиками. В БД ПУСТА — договорная работа не ведётся.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | — |
| `VendorID` | bigint | Поставщик | — |
| `ContractNumber` | varchar(50) | Номер договора | — |

**`receiving`** — Устаревшая таблица приёмки (формат journal), 17 строк.  
*Строк: 17.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transnumber` | numeric | Номер операции | 4 |
| `dater` | datetime | Дата | 2002-10-30 00:00:00.000 |
| `vendorid` | varchar(12) | Код поставщика (текст) | NULL |
| `quantity` | numeric | Количество | 10.000 |
| `cost` | numeric | Цена | 0.00 |

**`orders`** — Устаревшая таблица заказов поставщикам (формат journal), 6 строк.  
*Строк: 6.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ordern` | numeric | Номер заказа | 2 |
| `dater` | datetime | Дата | 2007-10-22 00:00:00.000 |
| `vendorid` | varchar(24) | Код поставщика (текст) | Cipla (Индия) |
| `orderquantity` | numeric | Заказанное количество | 0.000 |
| `cost` | numeric | Цена | 0.00 |


---

## 2. Анализ продажи товара

**Основные таблицы:** `journal`, `bm_Journal_Details`, `bm_JournalBarnetDocs`  
**Связанные таблицы:** `transtype`, `product`, `category`, `size`, `clients`, `clientgroup`, `recipe`, `bm_BonusHistory`, `bm_BarnetPortal_ExportHistory`, `paymenttype`, `bm_PaymentOperations`, `wastemessages`, `PreReceipt`

### 2.1 Связи между таблицами

| Дочерняя таблица.колонка | → | Родительская таблица.колонка | Тип связи |
|---|---|---|---|
| `journal.transtype` | → | `transtype.transtypeid` | FK |
| `bm_Journal_Details.SourceID` | → | `journal.transnumber` | FK |
| `bm_Journal_Details.ProductID` | → | `product.id` | FK |
| `bm_Journal_Details.BludoID` | → | `product.id` | FK |
| `bm_Journal_Details.RangeID` | → | `size.ID` | FK |
| `bm_Journal_Details.TicketNumber` | → | `journal.receiptn` | логическая (FK не объявлен; подтверждено выборкой) |
| `journal.id` | → | `product.productid` | логическая (FK не объявлен) |
| `journal.customerid` | → | `clients.clientid` | логическая (FK не объявлен) |
| `product.CategoryID` | → | `category.id` | FK |
| `clients.clientgroup` | → | `clientgroup.clientgroupid` | FK |
| `recipe.recipeid` | → | `product.id` | FK |
| `bm_JournalBarnetDocs.TicketNumber` | → | `journal.receiptn` | логическая (FK не объявлен) |
| `bm_BarnetPortal_ExportHistory.TicketNumber` | → | `journal.receiptn` | логическая (FK не объявлен) |
| `bm_BonusHistory.ClientID` | → | `clients.id` | логическая (FK не объявлен) |
| `bm_BonusHistory.TicketNumber` | → | `journal.receiptn` | логическая (FK не объявлен) |
| `bm_PaymentOperations.PaymentTypeID` | → | `paymenttype.paymenttypeid` | FK |
| `bm_PaymentOperations.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |

### 2.2 Описание таблиц

#### Основные таблицы

**`journal`** — Журнал продаж POS: одна строка = одна позиция чека (57 колонок, значимые перечислены).  
*Строк: 225 681.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transnumber` | bigint | Сквозной код строки (PK/уникален; на него ссылается bm_Journal_Details.SourceID) | н/д |
| `receiptn` | numeric | Номер чека | 14740696 |
| `dater` | datetime | Дата и время операции | 2020-11-11 10:09:39.000 |
| `transtype` | int | Тип операции → transtype.transtypeid | 101 |
| `id` | varchar(16) | Код товара = product.productid (varchar, FK не объявлен) | 524058 |
| `description` | varchar(50) | Наименование позиции на момент продажи | Пирог Камиль слоеный |
| `quantity` | numeric | Количество | 1.000 |
| `price` | numeric | Цена | 450.00 |
| `amount` | numeric | Сумма строки | 450.00 |
| `discountamount` | numeric | Сумма скидки | 0.00 |
| `cost` | numeric | Себестоимость | 0.00 |
| `customerid` | varchar(20) | Код клиента = clients.clientid (в выборке пусто) | (пусто) |
| `loginid` | varchar(13) | Код кассира/официанта (текст) | 906 |
| `tableid` | varchar(255) | Стол | н/д |
| `flagrefund` | tinyint | Признак возврата | 0 |

**`bm_Journal_Details`** — Расшифровка строки журнала: состав проданного блюда (ингредиенты) и склад списания.  
*Строк: 1 089 641.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 11530445 |
| `SourceID` | bigint | Строка журнала → journal.transnumber (FK) | 1675591 |
| `ProductID` | bigint | Ингредиент/товар → product.id (FK) | 4407 |
| `BludoID` | bigint | Блюдо → product.id (FK) | 4451 |
| `Quantity` | numeric | Количество порций проданного блюда | 1.0000 |
| `Count` | numeric | Норма ингредиента на порцию (доля единицы, например 0.4) | 0.4000 |
| `TicketNumber` | numeric | Номер чека = journal.receiptn (подтверждено выборкой) | 14740696 |
| `RangeID` | bigint | Единица → size.ID (FK) | 42 |
| `StorageID` | bigint | Склад списания | 41 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 1216 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 1 |
| `ShiftID` | bigint | Смена → bm_ShiftsOperations.ID | 65 |
| `Period` | datetime | Дата документа | 2013-07-23 10:00:00.000 |
| `TicketNumber` | numeric | Номер чека (связь с журналом продаж) | NULL |
| `Amount` | numeric | Сумма документа | 0.00 |
| `PersonID` | bigint | Сотрудник-автор → personnel.personid (FK не объявлен) | 897 |

#### Связанные таблицы

**`transtype`** — Справочник типов операций журнала.  
*Строк: 81.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transtypeid` | int | Код (PK) | 101 |
| `transgroupid` | int | Группа операций | 1 |
| `description` | varchar(max) | Описание | PLU Sales (14 — Rent, 15 — Lottery) |

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 4337 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | 1204073 |
| `description` | varchar(255) | Наименование | Бананы |
| `CategoryID` | bigint | Категория → category.id | н/д |
| `price1` | numeric | Розничная цена (уровень 1) | NULL |
| `cost` | numeric | Себестоимость | 0.00 |

**`category`** — Справочник категорий номенклатуры (дерево).  
*Строк: 158.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 147 |
| `description` | varchar(255) | Наименование | Меню доставка |
| `ParentID` | int | Родительская категория | 0 |

**`size`** — Справочник единиц/порций.  
*Строк: 78.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `description` | varchar(255) | Наименование | порция |

**`clients`** — Клиенты/гости (карты, скидки, бонусы).  
*Строк: 1 494.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 109 |
| `clientid` | varchar(24) | Бизнес-код клиента (= journal.customerid) | 1234 |
| `clientgroup` | int | Группа → clientgroup.clientgroupid (FK) | 37 |
| `cardid` | varchar(50) | Номер карты | (пусто) |
| `discount` | numeric | Персональная скидка, % | 0.000 |
| `bonus` | numeric | Бонусный счёт | 10.000 |

**`clientgroup`** — Группы клиентов (скидки, ценовой уровень).  
*Строк: 16.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `clientgroupid` | int | Код (PK) | 37 |
| `description` | varchar(24) | Название группы | Дсконт карты |
| `discount` | numeric | Скидка группы, % | 5.000 |

**`recipe`** — Рецептуры (техкарты): состав блюда.  
*Строк: 11 812.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 2806 |
| `DocumentID` | bigint | Документ техкарты → bm_JournalBarnetDocs.ID (FK) | 1216 |
| `recipeid` | bigint | Блюдо → product.id (FK) | 4420 |
| `ingredientid` | bigint | Ингредиент → product.id | 4391 |
| `portion` | numeric | Количество на порцию | 0.000 |
| `cost` | numeric | Себестоимость ингредиента | 0.00 |

**`bm_BonusHistory`** — История начисления/списания бонусов по чекам.  
*Строк: 44 866.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `ClientID` | bigint | Клиент → clients.id (FK не объявлен) | 3352 |
| `ActionName` | varchar(100) | Тип действия | User |
| `BonusValue` | numeric | Сумма бонусов | 0.00 |
| `Period` | datetime | Дата | 2016-04-05 11:31:10.553 |
| `TicketNumber` | varchar(25) | Номер чека (текст) | NULL |
| `PersonID` | int | Сотрудник → personnel.personid (FK) | 897 |

**`bm_BarnetPortal_ExportHistory`** — История выгрузки чеков на портал (по номеру чека).  
*Строк: 311 653.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1617 |
| `TicketNumber` | bigint | Номер выгруженного чека | 418467 |

**`paymenttype`** — Справочник видов оплаты.  
*Строк: 16.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `paymenttypeid` | int | Код (PK) | 211 |
| `description` | varchar(30) | Наименование | Наличные |
| `currencyid` | char(3) | Валюта | NULL (у 212 — USD) |

**`bm_PaymentOperations`** — Платежи по документам. В БД ПУСТА — оплата хранится вне этой таблицы.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | — |
| `PaymentTypeID` | int | Вид оплаты → paymenttype.paymenttypeid (FK) | — |
| `DocumentID` | bigint | Документ → bm_JournalBarnetDocs.ID (FK) | — |
| `Amount` | numeric | Сумма | — |

**`wastemessages`** — Сообщения о списаниях/отменах позиций в чеках (кто, когда, почему).  
*Строк: 3 582.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 1 |
| `receiptn` | numeric | Номер чека | 80400031 |
| `productid` | varchar(16) | Код товара = product.productid | 1009 |
| `dater` | datetime | Дата | 2008-04-13 14:25:08.000 |
| `quantity` | numeric | Количество | 1.000 |
| `amount` | numeric | Сумма | 120.000 |
| `reason` | varchar(255) | Причина (текст) | NULL |

**`PreReceipt`** — Предварительные чеки/брони (гости, время готовности). Без FK.  
*Строк: 10 767.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `TransNumber` | numeric | Номер | 1 |
| `ReceiptN` | numeric | Номер чека | 130200619 |
| `DateR` | datetime | Дата | 2013-02-26 09:21:05.473 |
| `Price` | numeric | Предварительная сумма | 200.00 |
| `NumPersons` | int | Число гостей | NULL |


---

## 3. Анализ взаимоотношений с поставщиками

**Основные таблицы:** `vendors`, `vendorgroup`, `pricelist`  
**Связанные таблицы:** `bm_StorageOperations`, `product`, `bm_JournalBarnetDocs`, `journal`, `stockperiod`, `bm_Companies`, `bm_Contracts`, `bm_PaymentOperations`, `bm_CashOperations`, `complaince`, `ordervendorinfo`, `conversionvendors`

### 3.1 Связи между таблицами

| Дочерняя таблица.колонка | → | Родительская таблица.колонка | Тип связи |
|---|---|---|---|
| `vendors.clientgroup` | → | `vendorgroup.vendorgroupid` | FK |
| `pricelist.vendorid` | → | `vendors.id` | логическая (FK не объявлен) |
| `pricelist.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |
| `bm_StorageOperations.VendorID` | → | `vendors.id` | логическая (FK не объявлен) |
| `bm_StorageOperations.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |
| `bm_StorageOperations.ProductID` | → | `product.id` | FK |
| `bm_StorageOperations.ContractID` | → | `bm_Contracts.ID` | логическая (FK не объявлен) |
| `product.vendorid` | → | `vendors.id` | логическая (FK не объявлен) |
| `journal.vendorid` | → | `vendors.clientid` | логическая (FK не объявлен) |
| `stockperiod.vendorid` | → | `vendors.clientid` | логическая (FK не объявлен) |
| `bm_JournalBarnetDocs.CompanyID` | → | `bm_Companies.ID` | FK |
| `bm_Contracts.CompanyID` | → | `bm_Companies.ID` | FK |
| `bm_Contracts.VendorID` | → | `vendors.id` | логическая (FK не объявлен) |
| `bm_PaymentOperations.ContractID` | → | `bm_Contracts.ID` | логическая (FK не объявлен) |
| `bm_CashOperations.VendorID` | → | `vendors.id` | логическая (FK не объявлен) |
| `complaince.CompanyID` | → | `bm_Companies.ID` | FK |
| `ordervendorinfo.vendorid` | → | `vendors.clientid` | логическая (FK не объявлен) |

### 3.2 Описание таблиц

#### Основные таблицы

**`vendors`** — Справочник поставщиков.  
*Строк: 63.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 91 |
| `clientid` | varchar(24) | Наименование поставщика (фактически хранит имя, а не код) | Габур |
| `clientgroup` | int | Группа → vendorgroup.vendorgroupid (FK) | 31 |
| `lastname` | varchar(100) | Фамилия/наименование (в выборке NULL — имя лежит в clientid) | NULL |
| `address` | varchar(40) | Адрес | NULL |
| `teln` | varchar(12) | Телефон | (пусто) |
| `emaliaddress` | varchar(30) | E-mail | (пусто) |
| `contactperson` | varchar(50) | Контактное лицо | NULL |
| `INN` | varchar(50) | ИНН | (пусто) |
| `KPP` | varchar(50) | КПП | (пусто) |
| `OGRN` | varchar(50) | ОГРН | (пусто) |
| `IsUse` | int | Признак «используется» | 1 |

**`vendorgroup`** — Группы поставщиков.  
*Строк: 2.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `vendorgroupid` | int | Код (PK) | 31 |
| `description` | varchar(100) | Наименование | Поставщики |
| `flag` | tinyint | Флаг | 0 |

**`pricelist`** — Прайс-листы поставщиков: цена товара у поставщика на дату действия.  
*Строк: 24 797.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код строки (PK) | 113681 |
| `DocumentID` | bigint | Документ-загрузка прайса → bm_JournalBarnetDocs.ID | 142417 |
| `productid` | bigint | Товар → product.id | 4544 |
| `vendorid` | bigint | Поставщик → vendors.id (в выборке NULL) | NULL |
| `description` | varchar(60) | Наименование у поставщика | NULL |
| `basecost` | numeric | Базовая закупочная цена | 140.00 |
| `dateeff` | date | Дата вступления цены в силу (в выборке NULL) | NULL |
| `distributor` | varchar(24) | Дистрибьютор (текст) | н/д |

#### Связанные таблицы

**`bm_StorageOperations`** — Складские движения (позиции складских документов): приход, расход, списание и т.д.  
*Строк: 1 031 198.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки движения (PK) | 4780421 |
| `DocumentID` | bigint | Документ-основание → bm_JournalBarnetDocs.ID | 388235 |
| `VendorID` | bigint | Поставщик → vendors.id (FK не объявлен) | 200 |
| `ContractID` | bigint | Договор → bm_Contracts.ID (таблица пуста) | 0 |
| `ProductID` | bigint | Товар/ингредиент → product.id | 4368 |
| `Amount` | numeric | Сумма строки | 892.77 |
| `DateAdd` | datetime | Дата добавления записи | 2020-11-15 14:15:30.183 |

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 4337 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | 1204073 |
| `description` | varchar(255) | Наименование | Бананы |
| `vendorid` | bigint | Основной поставщик → vendors.id (FK не объявлен) | 107 |
| `purchcost` | numeric | Закупочная цена | NULL |
| `lastreceived` | datetime | Дата последнего прихода | NULL |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 1216 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 1 |
| `CompanyID` | bigint | Организация → bm_Companies.ID | 6 |
| `Period` | datetime | Дата документа | 2013-07-23 10:00:00.000 |
| `Amount` | numeric | Сумма документа | 0.00 |

**`journal`** — Журнал продаж POS: одна строка = одна позиция чека (57 колонок, значимые перечислены).  
*Строк: 225 681.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transnumber` | bigint | Сквозной код строки (PK/уникален; на него ссылается bm_Journal_Details.SourceID) | н/д |
| `receiptn` | numeric | Номер чека | 14740696 |
| `id` | varchar(16) | Код товара = product.productid (varchar, FK не объявлен) | 524058 |
| `vendorid` | varchar(18) | Код поставщика позиции (в выборке пусто) | (пусто) |
| `amount` | numeric | Сумма строки | 450.00 |

**`stockperiod`** — Остатки и обороты по товарам за период (открытие/приход/расход/закрытие).  
*Строк: 56.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 1 |
| `productid` | varchar(16) | Код товара = product.productid (в выборке пусто) | (пусто) |
| `vendorid` | varchar(12) | Код поставщика (текст) | (пусто) |
| `quantityin` | numeric | Приход | 10000.000 |
| `datestart` | datetime | Начало периода | 2015-02-17 08:20:36.540 |
| `datefinish` | datetime | Конец периода | 2015-02-17 08:20:36.540 |

**`bm_Companies`** — Организации (юрлица).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 6 |
| `ShortName` | varchar(255) | Краткое наименование | Пиzzбург |
| `INN` | varchar(50) | ИНН | 380122679974 |

**`bm_Contracts`** — Договоры с поставщиками. В БД ПУСТА — договорная работа не ведётся.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | — |
| `CompanyID` | bigint | Организация → bm_Companies.ID | — |
| `VendorID` | bigint | Поставщик | — |
| `ContractNumber` | varchar(50) | Номер договора | — |
| `Period` | datetime | Дата договора | — |

**`bm_PaymentOperations`** — Платежи по документам. В БД ПУСТА — оплата хранится вне этой таблицы.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | — |
| `ContractID` | bigint | Договор → bm_Contracts.ID (FK не объявлен) | — |
| `Amount` | numeric | Сумма | — |

**`bm_CashOperations`** — Кассовые операции (в т.ч. выплаты поставщикам). ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `VendorID` | bigint | Поставщик | — |
| `Amount` | numeric | Сумма | — |

**`complaince`** — Лицензии/соответствие организации. ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `CompanyID` | bigint | Организация → bm_Companies.ID (FK) | — |
| `description` | varchar(255) | Описание | — |

**`ordervendorinfo`** — Условия заказа у поставщика (кратность, мин. партия). ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `vendorid` | varchar(12) | Поставщик | — |
| `minfororder` | numeric | Мин. заказ | — |

**`conversionvendors`** — Конвертация прайсов поставщиков. ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `vendorid` | varchar(24) | Код поставщика | — |


---

## 4. Анализ работы персонала

**Основные таблицы:** `personnel`, `bm_PersonnelSecurity`, `bm_JournalSessions`  
**Связанные таблицы:** `securityaccess`, `bm_SecurityObjects`, `bm_SecurityObjects_Info`, `bm_BonusHistory`, `bm_JournalBarnetDocs`, `journal`, `wastemessages`, `bm_ShiftsOperations`, `bm_WorkHours`, `bm_TicketLoadInfo_History`

### 4.1 Связи между таблицами

| Дочерняя таблица.колонка | → | Родительская таблица.колонка | Тип связи |
|---|---|---|---|
| `personnel.securityaccess` | → | `securityaccess.securityaccessid` | логическая (FK не объявлен) |
| `bm_PersonnelSecurity.PersonID` | → | `personnel.personid` | логическая (FK не объявлен) |
| `bm_PersonnelSecurity.ObjectID` | → | `bm_SecurityObjects.ID` | FK |
| `bm_SecurityObjects_Info.ParentID` | → | `bm_SecurityObjects.ID` | FK |
| `bm_BonusHistory.PersonID` | → | `personnel.personid` | FK |
| `bm_JournalSessions.PersonID` | → | `personnel.personid` | логическая (FK не объявлен) |
| `bm_JournalBarnetDocs.PersonID` | → | `personnel.personid` | логическая (FK не объявлен) |
| `bm_JournalBarnetDocs.ShiftID` | → | `bm_ShiftsOperations.ID` | FK |
| `bm_ShiftsOperations.PersonalID` | → | `personnel.personid` | логическая (FK не объявлен) |
| `journal.loginid` | → | `personnel.personid` | логическая (FK не объявлен) |
| `wastemessages.loginid` | → | `personnel.personid` | логическая (FK не объявлен) |
| `wastemessages.managerid` | → | `personnel.personid` | логическая (FK не объявлен) |
| `bm_WorkHours.PersonID` | → | `personnel.personid` | логическая (FK не объявлен) |
| `bm_TicketLoadInfo_History.PersonnelID` | → | `personnel.personid` | логическая (FK не объявлен) |

### 4.2 Описание таблиц

#### Основные таблицы

**`personnel`** — Сотрудники (42 колонки, значимые перечислены).  
*Строк: 109.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `personid` | int | Код сотрудника (PK) | 897 |
| `lastname` | varchar(45) | Фамилия | (пусто) |
| `firstname` | varchar(25) | Имя | Администратор Barnet |
| `middlename` | varchar(50) | Отчество | (пусто) |
| `securityaccess` | int | Уровень доступа → securityaccess.securityaccessid (FK не объявлен) | 9 |
| `flagsales` | tinyint | Право на продажи | 0 |
| `flagrefunds` | tinyint | Право на возвраты | 0 |
| `flagdiscounts` | tinyint | Право на скидки | 0 |
| `bartender` | tinyint | Признак бармена | 0 |
| `cardid` | varchar(50) | Номер карты сотрудника | 0 |
| `deleteflag` | tinyint | Признак удаления/увольнения | 1 |

**`bm_PersonnelSecurity`** — Права сотрудников на объекты безопасности (матрица доступа).  
*Строк: 1 402.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1397 |
| `PersonID` | bigint | Сотрудник → personnel.personid (FK не объявлен) | 906 |
| `ObjectID` | bigint | Объект → bm_SecurityObjects.ID (FK) | 36 |
| `IsUse` | int | Право выдано | 1 |

**`bm_JournalSessions`** — Журнал сессий и событий приложения (действия пользователей, ошибки).  
*Строк: 174 072.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `Type` | varchar(100) | Тип события | Система |
| `Message` | varchar(max) | Текст события | Произведена очистка журнала системных сообщений. |
| `IsError` | int | Признак ошибки | 0 |
| `DateAdd` | datetime | Дата события | 2019-10-10 10:09:48.707 |
| `UserAdd` | varchar(50) | Пользователь (текст) | userdb |
| `PersonID` | bigint | Сотрудник → personnel.personid (FK не объявлен) | 897 |

#### Связанные таблицы

**`securityaccess`** — Справочник уровней доступа.  
*Строк: 4.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `securityaccessid` | int | Код (PK) | 3 |
| `description` | varchar(30) | Наименование | Manager/Adm (2 — Clerk, 9 — Special Access) |

**`bm_SecurityObjects`** — Справочник объектов безопасности (формы, операции).  
*Строк: 214.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `ParentSystem` | varchar(50) | Система/модуль | Manager |
| `SecurityGroup` | varchar(100) | Группа | Прочее |
| `ObjectName` | varchar(250) | Системное имя | dlgProperties |
| `Description` | varchar(max) | Описание | Форма настроек |

**`bm_SecurityObjects_Info`** — Параметры объектов безопасности (ключ-значение).  
*Строк: 1 570.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 33 |
| `ParentID` | bigint | Объект → bm_SecurityObjects.ID (FK) | 194 |
| `KeyName` | varchar(50) | Ключ | Splitter1Distance |
| `KeyValue` | varchar(max) | Значение | 201 |
| `ManagerID` | bigint | Менеджер | 920 |

**`bm_BonusHistory`** — История начисления/списания бонусов по чекам.  
*Строк: 44 866.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `ClientID` | bigint | Клиент → clients.id (FK не объявлен) | 3352 |
| `ActionName` | varchar(100) | Тип действия | User |
| `BonusValue` | numeric | Сумма бонусов | 0.00 |
| `Period` | datetime | Дата | 2016-04-05 11:31:10.553 |
| `PersonID` | int | Сотрудник → personnel.personid (FK) | 897 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 1216 |
| `ShiftID` | bigint | Смена → bm_ShiftsOperations.ID | 65 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 1 |
| `Amount` | numeric | Сумма документа | 0.00 |
| `DateAdd` | datetime | Дата создания | 2013-07-23 17:45:46.217 |
| `UserAdd` | varchar(150) | Пользователь-автор (текст) | userdb |
| `PersonID` | bigint | Сотрудник-автор → personnel.personid (FK не объявлен) | 897 |

**`journal`** — Журнал продаж POS: одна строка = одна позиция чека (57 колонок, значимые перечислены).  
*Строк: 225 681.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transnumber` | bigint | Сквозной код строки (PK/уникален; на него ссылается bm_Journal_Details.SourceID) | н/д |
| `receiptn` | numeric | Номер чека | 14740696 |
| `dater` | datetime | Дата и время операции | 2020-11-11 10:09:39.000 |
| `amount` | numeric | Сумма строки | 450.00 |
| `discountamount` | numeric | Сумма скидки | 0.00 |
| `loginid` | varchar(13) | Код кассира/официанта (текст) | 906 |
| `flagrefund` | tinyint | Признак возврата | 0 |
| `ManagerName` | varchar(255) | Менеджер, подтвердивший операцию | н/д |

**`wastemessages`** — Сообщения о списаниях/отменах позиций в чеках (кто, когда, почему).  
*Строк: 3 582.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 1 |
| `receiptn` | numeric | Номер чека | 80400031 |
| `dater` | datetime | Дата | 2008-04-13 14:25:08.000 |
| `loginid` | varchar(13) | Кто отменил | 1 |
| `amount` | numeric | Сумма | 120.000 |
| `managerid` | varchar(13) | Менеджер, подтвердивший | 1 |
| `reason` | varchar(255) | Причина (текст) | NULL |

**`bm_ShiftsOperations`** — Кассовые смены (в БД одна запись).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 65 |
| `ShiftNumber` | varchar(50) | Номер смены | 1 |
| `Amount` | numeric | Выручка смены | 0.00 |
| `DateAdd` | datetime | Открытие | 2015-07-14 10:29:13.470 |
| `PersonalID` | bigint | Сотрудник → personnel.personid (FK не объявлен) | 0 |

**`bm_WorkHours`** — Учёт отработанного времени. ПУСТА — табель не ведётся.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `PersonID` | int | Сотрудник | — |
| `DateR` | datetime | Дата | — |
| `SystemPeriod` | float | Часы по системе | — |
| `ManualPeriod` | float | Часы вручную | — |

**`bm_TicketLoadInfo_History`** — История загрузки чеков (ошибки загрузки, кто загружал).  
*Строк: 88.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 2 |
| `CalcPeriod` | varchar(255) | Период расчёта | от 2020-11-18 16:34 до 2023-12-04 20:13 |
| `TicketNumber` | bigint | Номер чека | 11876767 |
| `Errors` | varchar(max) | Текст ошибки | Чек: 11876767 поступил в обработку |
| `PersonnelID` | bigint | Сотрудник → personnel.personid | 0 |


---

## 5. Анализ остатков

**Основные таблицы:** `product`, `bm_StorageOperations`, `stockperiod`  
**Связанные таблицы:** `bm_StorageOperationsType`, `bm_StorageOperations_Table`, `storages`, `category`, `size`, `bm_ReasonDebit`, `wastemessages`, `beginperiod`, `bm_JournalBarnetDocs`, `closingcount`, `onhand`, `storagesonhand`, `stock`

### 5.1 Связи между таблицами

| Дочерняя таблица.колонка | → | Родительская таблица.колонка | Тип связи |
|---|---|---|---|
| `bm_StorageOperations.ProductID` | → | `product.id` | FK |
| `bm_StorageOperations.StorageID` | → | `storages.id` | FK |
| `bm_StorageOperations.OperationID` | → | `bm_StorageOperationsType.ID` | FK |
| `bm_StorageOperations.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |
| `bm_StorageOperations.ReasonID` | → | `bm_ReasonDebit.ID` | логическая (FK не объявлен) |
| `bm_StorageOperations_Table.ProductID` | → | `product.id` | FK |
| `bm_StorageOperations_Table.StorageID` | → | `storages.id` | FK |
| `bm_StorageOperations_Table.OperationID` | → | `bm_StorageOperationsType.ID` | FK |
| `bm_StorageOperations_Table.DocumentID` | → | `bm_JournalBarnetDocs.ID` | FK |
| `product.CategoryID` | → | `category.id` | FK |
| `category.StorageID` | → | `storages.id` | логическая (FK не объявлен) |
| `stockperiod.productid` | → | `product.productid` | логическая (FK не объявлен) |
| `wastemessages.productid` | → | `product.productid` | логическая (FK не объявлен) |
| `closingcount.productid` | → | `product.id` | FK |
| `storagesonhand.productid` | → | `product.productid` | логическая (FK не объявлен) |
| `storagesonhand.storageid` | → | `storages.id` | логическая (FK не объявлен) |
| `onhand.productid` | → | `product.productid` | логическая (FK не объявлен) |
| `bm_ReasonDebit.ParentID` | → | `bm_ReasonDebit.ID` | логическая (FK не объявлен) |

### 5.2 Описание таблиц

#### Основные таблицы

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 4337 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | 1204073 |
| `description` | varchar(255) | Наименование | Бананы |
| `CategoryID` | bigint | Категория → category.id | н/д |
| `onhand` | numeric | Текущий остаток (в выборке NULL) | NULL |
| `onhandg` | numeric | Остаток в граммах/мл (альтернативная единица) | н/д |
| `minstockrate` | numeric | Неснижаемый остаток | 0.00 |
| `minfororder` | numeric | Минимум для заказа | 0.00 |
| `lastreceived` | datetime | Дата последнего прихода | NULL |
| `lastsold` | datetime | Дата последней продажи | NULL |
| `closingcount` | numeric | Результат последней инвентаризации | 0.000 |
| `closingcountdate` | datetime | Дата последней инвентаризации | NULL |
| `IsUse` | int | Признак «используется» | н/д |

**`bm_StorageOperations`** — Складские движения (позиции складских документов): приход, расход, списание и т.д.  
*Строк: 1 031 198.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки движения (PK) | 4780421 |
| `DocumentID` | bigint | Документ-основание → bm_JournalBarnetDocs.ID | 388235 |
| `OperationID` | bigint | Вид операции → bm_StorageOperationsType.ID | 1 |
| `ProductID` | bigint | Товар/ингредиент → product.id | 4368 |
| `StorageID` | bigint | Склад → storages.id | 41 |
| `Quantity` | numeric | Количество (в выборке 0.0000 при ненулевой сумме — см. также Count) | 0.0000 |
| `Rest` | numeric | Остаток после операции (в выборке 0.0000) | 0.0000 |
| `Amount` | numeric | Сумма строки | 892.77 |
| `ReasonID` | bigint | Причина списания → bm_ReasonDebit.ID (FK не объявлен) | NULL |
| `DateAdd` | datetime | Дата добавления записи | 2020-11-15 14:15:30.183 |

**`stockperiod`** — Остатки и обороты по товарам за период (открытие/приход/расход/закрытие).  
*Строк: 56.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 1 |
| `storeid` | int | Точка/склад | 1 |
| `productid` | varchar(16) | Код товара = product.productid (в выборке пусто) | (пусто) |
| `quantityopen` | numeric | Остаток на начало | 0.000 |
| `quantityin` | numeric | Приход | 10000.000 |
| `quantityout` | numeric | Расход | 14999.000 |
| `quantityclose` | numeric | Остаток на конец | 0.000 |
| `datestart` | datetime | Начало периода | 2015-02-17 08:20:36.540 |
| `datefinish` | datetime | Конец периода | 2015-02-17 08:20:36.540 |

#### Связанные таблицы

**`bm_StorageOperationsType`** — Справочник видов складских операций; Factor задаёт знак (+1 приход / −1 расход).  
*Строк: 5.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код вида операции (PK) | 1 |
| `Description` | varchar(max) | Наименование операции | Поступление (2 — Списание, −1; 3 — Инвентаризация, +1) |
| `Factor` | int | Множитель остатка: +1 или −1 | 1 |

**`bm_StorageOperations_Table`** — Строки складских операций с клиентом/торговым агентом и скидкой; в выборке — списания (OperationID = 2) с причиной.  
*Строк: 30 801.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки (PK) | 134198 |
| `DocumentID` | bigint | Документ → bm_JournalBarnetDocs.ID | 388540 |
| `OperationID` | bigint | Вид операции → bm_StorageOperationsType.ID | 2 |
| `StorageID` | bigint | Склад → storages.id | 41 |
| `ProductID` | bigint | Товар → product.id | 4345 |
| `Quantity` | numeric | Количество | 0.0000 |
| `Rest` | numeric | Остаток после операции | 0.0000 |
| `ReasonID` | bigint | Причина → bm_ReasonDebit.ID | 24 |
| `DateAdd` | datetime | Дата записи | 2020-11-15 18:05:37.700 |

**`storages`** — Склады (в БД — одна запись).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код склада (PK) | 41 |
| `description` | varchar(255) | Наименование склада | Склад |
| `ResponsibleID` | int | Ответственный сотрудник → personnel.personid | 897 |

**`category`** — Справочник категорий номенклатуры (дерево).  
*Строк: 158.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 147 |
| `description` | varchar(255) | Наименование | Меню доставка |
| `StorageID` | int | Склад по умолчанию → storages.id (FK не объявлен) | 41 |

**`size`** — Справочник единиц/порций.  
*Строк: 78.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `description` | varchar(255) | Наименование | порция |

**`bm_ReasonDebit`** — Справочник причин списания (иерархия).  
*Строк: 47.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код причины (PK) | 1 |
| `ParentID` | bigint | Родительская причина | 0 |
| `Description` | varchar(255) | Наименование причины | Порча продукта |

**`wastemessages`** — Сообщения о списаниях/отменах позиций в чеках (кто, когда, почему).  
*Строк: 3 582.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 1 |
| `productid` | varchar(16) | Код товара = product.productid | 1009 |
| `dater` | datetime | Дата | 2008-04-13 14:25:08.000 |
| `quantity` | numeric | Количество | 1.000 |
| `amount` | numeric | Сумма | 120.000 |
| `reason` | varchar(255) | Причина (текст) | NULL |

**`beginperiod`** — Даты начала учётных периодов.  
*Строк: 23.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 17 |
| `datestart` | datetime | Дата начала периода | 2009-03-17 11:00:00.000 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 1216 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 1 |
| `Period` | datetime | Дата документа | 2013-07-23 10:00:00.000 |

**`closingcount`** — Результаты инвентаризации. ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `productid` | bigint | Товар → product.id (FK) | — |
| `closingcount` | numeric | Фактический остаток | — |
| `closingcountdate` | datetime | Дата | — |

**`onhand`** — Остатки по точкам. ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `productid` | varchar(16) | Код товара | — |
| `onhand` | numeric | Остаток | — |

**`storagesonhand`** — Остатки по складам. ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `productid` | varchar(16) | Код товара | — |
| `storageid` | bigint | Склад | — |
| `onhand` | numeric | Остаток | — |

**`stock`** — Витрина остатков/оборотов. ПУСТА.  
*Строк: 0 — пусто.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `productid` | varchar(16) | Код товара | — |
| `onhand` | numeric | Остаток | — |

