# Front: описание таблиц и связей по направлениям анализа

> Источник: `table_info.csv`, `column_info.csv`, `relation_info.csv`. СУБД: Microsoft SQL Server, схема `dbo`.

- **Основные** таблицы группы — где хранятся факты; **связанные** — справочники и соседние сущности.
- Указаны только значимые для группы колонки. Типы и число строк — из CSV; **«Пример данных» иллюстративный** (содержимого БД не было).
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
| `ID` | bigint | Код строки движения (PK) | 1031198 |
| `DocumentID` | bigint | Документ-основание → bm_JournalBarnetDocs.ID | 55012 |
| `OperationID` | bigint | Вид операции → bm_StorageOperationsType.ID | 1 |
| `VendorID` | bigint | Поставщик → vendors.id (FK не объявлен) | 17 |
| `ContractID` | bigint | Договор → bm_Contracts.ID (таблица пуста) | 0 |
| `ProductID` | bigint | Товар/ингредиент → product.id | 812 |
| `StorageID` | bigint | Склад → storages.id | 1 |
| `Price` | numeric | Цена | 420.00 |
| `PriceCost` | numeric | Себестоимость единицы | 310.50 |
| `Quantity` | numeric | Количество (в базовых единицах) | 12.000 |
| `Amount` | numeric | Сумма строки | 5040.00 |
| `DateAdd` | datetime | Дата добавления записи | 2026-09-12 10:15:00 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 55012 |
| `JournalID` | bigint | Журнал → bm_JournalType.ID | 2 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 4 |
| `CompanyID` | bigint | Организация → bm_Companies.ID | 1 |
| `DocumentNumber` | bigint | Номер документа | 1045 |
| `Period` | datetime | Дата документа | 2026-09-12 |
| `Amount` | numeric | Сумма документа | 25400.00 |
| `IsUse` | int | Признак «проведён/действует» | 1 |

**`pricelist`** — Прайс-листы поставщиков: цена товара у поставщика на дату действия.  
*Строк: 24 797.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код строки (PK) | 24797 |
| `DocumentID` | bigint | Документ-загрузка прайса → bm_JournalBarnetDocs.ID | 54001 |
| `productid` | bigint | Товар → product.id | 812 |
| `vendorid` | bigint | Поставщик → vendors.id (FK не объявлен) | 17 |
| `basecost` | numeric | Базовая закупочная цена | 980.00 |
| `oldbasecost` | numeric | Предыдущая цена | 950.00 |
| `dateeff` | date | Дата вступления цены в силу | 2026-09-01 |
| `groupid` | int | Ценовая группа → pricegroup.pricegroupid | 1 |

#### Связанные таблицы

**`bm_StorageOperationsType`** — Справочник видов складских операций; Factor задаёт знак (+1 приход / −1 расход).  
*Строк: 5.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код вида операции (PK) | 1 |
| `Description` | varchar(max) | Наименование операции | Приход от поставщика |
| `Factor` | int | Множитель остатка: +1 или −1 | 1 |

**`bm_JournalTypeDocuments`** — Справочник типов документов внутри журнала.  
*Строк: 25.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код типа документа (PK) | 4 |
| `Description` | varchar(max) | Наименование типа | Приходная накладная |
| `JournalID` | bigint | Журнал → bm_JournalType.ID | 2 |

**`bm_JournalType`** — Справочник журналов (склад, касса, прайс-листы…).  
*Строк: 6.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код журнала (PK) | 2 |
| `JournalName` | varchar(255) | Название журнала | Складской журнал |

**`vendors`** — Справочник поставщиков.  
*Строк: 63.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 17 |
| `clientid` | varchar(24) | Бизнес-код поставщика | V0017 |
| `lastname` | varchar(100) | Наименование/фамилия | ООО «Вина Юга» |
| `INN` | varchar(50) | ИНН | 7700000000 |
| `IsUse` | int | Признак «используется» | 1 |

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 812 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | C0042 |
| `description` | varchar(255) | Наименование | Мохито |
| `vendorid` | bigint | Основной поставщик → vendors.id (FK не объявлен) | 17 |
| `CategoryID` | bigint | Категория → category.id | 12 |
| `purchcost` | numeric | Закупочная цена | 85.00 |
| `lastreceived` | datetime | Дата последнего прихода | 2026-09-10 00:00:00 |

**`category`** — Справочник категорий номенклатуры (дерево).  
*Строк: 158.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 12 |
| `description` | varchar(255) | Наименование | Коктейли |
| `ParentID` | int | Родительская категория | 3 |

**`size`** — Справочник единиц/порций.  
*Строк: 78.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 5 |
| `description` | varchar(255) | Наименование | Порция 50 мл |

**`storages`** — Склады (в БД — одна запись).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код склада (PK) | 1 |
| `description` | varchar(255) | Наименование склада | Основной склад |
| `CompanyID` | int | Организация → bm_Companies.ID (FK не объявлен) | 1 |

**`bm_Companies`** — Организации (юрлица).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `ShortName` | varchar(255) | Краткое наименование | Пример |
| `INN` | varchar(50) | ИНН | 7700000000 |

**`bm_ReasonDebit`** — Справочник причин списания (иерархия).  
*Строк: 47.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код причины (PK) | 3 |
| `ParentID` | bigint | Родительская причина | 1 |
| `Description` | varchar(255) | Наименование причины | Бой посуды / порча |

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
| `transnumber` | numeric | Номер операции | 1 |
| `dater` | datetime | Дата | 2020-01-01 00:00:00 |
| `vendorid` | varchar(12) | Код поставщика (текст) | 17 |
| `quantity` | numeric | Количество | 12 |
| `cost` | numeric | Цена | 980.00 |

**`orders`** — Устаревшая таблица заказов поставщикам (формат journal), 6 строк.  
*Строк: 6.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ordern` | numeric | Номер заказа | 1 |
| `dater` | datetime | Дата | 2020-01-01 00:00:00 |
| `vendorid` | varchar(24) | Код поставщика (текст) | 17 |
| `orderquantity` | numeric | Заказанное количество | 12 |
| `cost` | numeric | Цена | 980.00 |


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
| `transnumber` | bigint | Сквозной код строки (PK/уникален; на него ссылается bm_Journal_Details.SourceID) | 5000123 |
| `receiptn` | numeric | Номер чека | 10452 |
| `dater` | datetime | Дата и время операции | 2026-09-12 21:14:05 |
| `transtype` | int | Тип операции → transtype.transtypeid | 1 |
| `id` | varchar(16) | Код товара = product.productid (varchar, FK не объявлен) | C0042 |
| `description` | varchar(50) | Наименование позиции на момент продажи | Мохито |
| `quantity` | numeric | Количество | 2.000 |
| `price` | numeric | Цена | 350.00 |
| `amount` | numeric | Сумма строки | 700.00 |
| `discountamount` | numeric | Сумма скидки | 35.00 |
| `cost` | numeric | Себестоимость | 90.00 |
| `customerid` | varchar(20) | Код клиента = clients.clientid (FK не объявлен) | CL000123 |
| `loginid` | varchar(13) | Код кассира/официанта (текст) | 17 |
| `tableid` | varchar(255) | Стол | Стол 5 |
| `flagrefund` | tinyint | Признак возврата | 0 |

**`bm_Journal_Details`** — Расшифровка строки журнала: состав проданного блюда (ингредиенты) и склад списания.  
*Строк: 1 089 641.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1089641 |
| `SourceID` | bigint | Строка журнала → journal.transnumber (FK) | 5000123 |
| `ProductID` | bigint | Ингредиент/товар → product.id (FK) | 812 |
| `BludoID` | bigint | Блюдо → product.id (FK) | 301 |
| `Quantity` | numeric | Количество ингредиента | 0.050 |
| `Count` | numeric | Количество порций | 2 |
| `TicketNumber` | numeric | Номер чека | 10452 |
| `RangeID` | bigint | Единица → size.ID (FK) | 5 |
| `StorageID` | bigint | Склад списания | 1 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 55012 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 4 |
| `ShiftID` | bigint | Смена → bm_ShiftsOperations.ID | 1 |
| `Period` | datetime | Дата документа | 2026-09-12 |
| `TicketNumber` | numeric | Номер чека (связь с журналом продаж) | 10452 |
| `Amount` | numeric | Сумма документа | 25400.00 |
| `PersonID` | bigint | Сотрудник-автор → personnel.personid (FK не объявлен) | 17 |

#### Связанные таблицы

**`transtype`** — Справочник типов операций журнала.  
*Строк: 81.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transtypeid` | int | Код (PK) | 1 |
| `transgroupid` | int | Группа операций | 1 |
| `description` | varchar(max) | Описание | Продажа |

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 812 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | C0042 |
| `description` | varchar(255) | Наименование | Мохито |
| `CategoryID` | bigint | Категория → category.id | 12 |
| `price1` | numeric | Розничная цена (уровень 1) | 350.00 |
| `cost` | numeric | Себестоимость | 90.00 |

**`category`** — Справочник категорий номенклатуры (дерево).  
*Строк: 158.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 12 |
| `description` | varchar(255) | Наименование | Коктейли |
| `ParentID` | int | Родительская категория | 3 |

**`size`** — Справочник единиц/порций.  
*Строк: 78.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 5 |
| `description` | varchar(255) | Наименование | Порция 50 мл |

**`clients`** — Клиенты/гости (карты, скидки, бонусы).  
*Строк: 1 494.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 120 |
| `clientid` | varchar(24) | Бизнес-код клиента (= journal.customerid) | CL000123 |
| `clientgroup` | int | Группа → clientgroup.clientgroupid (FK) | 3 |
| `cardid` | varchar(50) | Номер карты | 2000000012345 |
| `discount` | numeric | Персональная скидка, % | 10.00 |
| `bonus` | numeric | Бонусный счёт | 350.00 |

**`clientgroup`** — Группы клиентов (скидки, ценовой уровень).  
*Строк: 16.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `clientgroupid` | int | Код (PK) | 3 |
| `description` | varchar(24) | Название группы | Постоянные гости |
| `discount` | numeric | Скидка группы, % | 10.00 |

**`recipe`** — Рецептуры (техкарты): состав блюда.  
*Строк: 11 812.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 11812 |
| `DocumentID` | bigint | Документ техкарты → bm_JournalBarnetDocs.ID (FK) | 53000 |
| `recipeid` | bigint | Блюдо → product.id (FK) | 301 |
| `ingredientid` | bigint | Ингредиент → product.id | 812 |
| `portion` | numeric | Количество на порцию | 0.050 |
| `cost` | numeric | Себестоимость ингредиента | 4.25 |

**`bm_BonusHistory`** — История начисления/списания бонусов по чекам.  
*Строк: 44 866.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 44866 |
| `ClientID` | bigint | Клиент → clients.id (FK не объявлен) | 120 |
| `ActionName` | varchar(100) | Тип действия | Начисление |
| `BonusValue` | numeric | Сумма бонусов | 35.00 |
| `Period` | datetime | Дата | 2026-09-12 21:15:00 |
| `TicketNumber` | varchar(25) | Номер чека (текст) | 10452 |
| `PersonID` | int | Сотрудник → personnel.personid (FK) | 17 |

**`bm_BarnetPortal_ExportHistory`** — История выгрузки чеков на портал (по номеру чека).  
*Строк: 311 653.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 311653 |
| `TicketNumber` | bigint | Номер выгруженного чека | 10452 |

**`paymenttype`** — Справочник видов оплаты.  
*Строк: 16.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `paymenttypeid` | int | Код (PK) | 1 |
| `description` | varchar(30) | Наименование | Наличные |
| `currencyid` | char(3) | Валюта | RUB |

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
| `id` | bigint | Код (PK) | 3582 |
| `receiptn` | numeric | Номер чека | 10452 |
| `productid` | varchar(16) | Код товара = product.productid | C0042 |
| `dater` | datetime | Дата | 2026-09-12 21:30:00 |
| `quantity` | numeric | Количество | 1.000 |
| `amount` | numeric | Сумма | 350.00 |
| `reason` | varchar(255) | Причина (текст) | Ошибка официанта |

**`PreReceipt`** — Предварительные чеки/брони (гости, время готовности). Без FK.  
*Строк: 10 767.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `TransNumber` | numeric | Номер | 10767 |
| `ReceiptN` | numeric | Номер чека | 10452 |
| `DateR` | datetime | Дата | 2026-09-12 20:00:00 |
| `Price` | numeric | Предварительная сумма | 2500.00 |
| `NumPersons` | int | Число гостей | 4 |


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
| `id` | bigint | Код (PK) | 17 |
| `clientid` | varchar(24) | Бизнес-код поставщика | V0017 |
| `clientgroup` | int | Группа → vendorgroup.vendorgroupid (FK) | 1 |
| `lastname` | varchar(100) | Наименование/фамилия | ООО «Вина Юга» |
| `address` | varchar(40) | Адрес | г. Пример, ул. Складская, 5 |
| `teln` | varchar(12) | Телефон | 4950000000 |
| `emaliaddress` | varchar(30) | E-mail | sales@example.ru |
| `contactperson` | varchar(50) | Контактное лицо | Сидоров А. |
| `INN` | varchar(50) | ИНН | 7700000000 |
| `KPP` | varchar(50) | КПП | 770001001 |
| `OGRN` | varchar(50) | ОГРН | 1000000000000 |
| `IsUse` | int | Признак «используется» | 1 |

**`vendorgroup`** — Группы поставщиков.  
*Строк: 2.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `vendorgroupid` | int | Код (PK) | 1 |
| `description` | varchar(100) | Наименование | Алкоголь |
| `flag` | tinyint | Флаг | 0 |

**`pricelist`** — Прайс-листы поставщиков: цена товара у поставщика на дату действия.  
*Строк: 24 797.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код строки (PK) | 24797 |
| `DocumentID` | bigint | Документ-загрузка прайса → bm_JournalBarnetDocs.ID | 54001 |
| `productid` | bigint | Товар → product.id | 812 |
| `vendorid` | bigint | Поставщик → vendors.id (FK не объявлен) | 17 |
| `description` | varchar(60) | Наименование у поставщика | Ром тёмный 0.7л |
| `basecost` | numeric | Базовая закупочная цена | 980.00 |
| `dateeff` | date | Дата вступления цены в силу | 2026-09-01 |
| `distributor` | varchar(24) | Дистрибьютор (текст) | Вина Юга |

#### Связанные таблицы

**`bm_StorageOperations`** — Складские движения (позиции складских документов): приход, расход, списание и т.д.  
*Строк: 1 031 198.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки движения (PK) | 1031198 |
| `DocumentID` | bigint | Документ-основание → bm_JournalBarnetDocs.ID | 55012 |
| `VendorID` | bigint | Поставщик → vendors.id (FK не объявлен) | 17 |
| `ContractID` | bigint | Договор → bm_Contracts.ID (таблица пуста) | 0 |
| `ProductID` | bigint | Товар/ингредиент → product.id | 812 |
| `Amount` | numeric | Сумма строки | 5040.00 |
| `DateAdd` | datetime | Дата добавления записи | 2026-09-12 10:15:00 |

**`product`** — Номенклатура: товары, блюда, напитки, ингредиенты (119 колонок, значимые перечислены).  
*Строк: 1 545.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Суррогатный код (PK) | 812 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | C0042 |
| `description` | varchar(255) | Наименование | Мохито |
| `vendorid` | bigint | Основной поставщик → vendors.id (FK не объявлен) | 17 |
| `purchcost` | numeric | Закупочная цена | 85.00 |
| `lastreceived` | datetime | Дата последнего прихода | 2026-09-10 00:00:00 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 55012 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 4 |
| `CompanyID` | bigint | Организация → bm_Companies.ID | 1 |
| `Period` | datetime | Дата документа | 2026-09-12 |
| `Amount` | numeric | Сумма документа | 25400.00 |

**`journal`** — Журнал продаж POS: одна строка = одна позиция чека (57 колонок, значимые перечислены).  
*Строк: 225 681.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transnumber` | bigint | Сквозной код строки (PK/уникален; на него ссылается bm_Journal_Details.SourceID) | 5000123 |
| `receiptn` | numeric | Номер чека | 10452 |
| `id` | varchar(16) | Код товара = product.productid (varchar, FK не объявлен) | C0042 |
| `vendorid` | varchar(18) | Код поставщика позиции (текст) | 17 |
| `amount` | numeric | Сумма строки | 700.00 |

**`stockperiod`** — Остатки и обороты по товарам за период (открытие/приход/расход/закрытие).  
*Строк: 56.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 56 |
| `productid` | varchar(16) | Код товара = product.productid | C0042 |
| `vendorid` | varchar(12) | Код поставщика (текст) | 17 |
| `quantityin` | numeric | Приход | 30.000 |
| `datestart` | datetime | Начало периода | 2026-09-01 00:00:00 |
| `datefinish` | datetime | Конец периода | 2026-09-30 23:59:59 |

**`bm_Companies`** — Организации (юрлица).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `ShortName` | varchar(255) | Краткое наименование | Пример |
| `INN` | varchar(50) | ИНН | 7700000000 |

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
| `personid` | int | Код сотрудника (PK) | 17 |
| `lastname` | varchar(45) | Фамилия | Иванов |
| `firstname` | varchar(25) | Имя | Иван |
| `middlename` | varchar(50) | Отчество | Иванович |
| `securityaccess` | int | Уровень доступа → securityaccess.securityaccessid (FK не объявлен) | 2 |
| `flagsales` | tinyint | Право на продажи | 1 |
| `flagrefunds` | tinyint | Право на возвраты | 0 |
| `flagdiscounts` | tinyint | Право на скидки | 0 |
| `bartender` | tinyint | Признак бармена | 1 |
| `cardid` | varchar(50) | Номер карты сотрудника | 1000000017 |
| `deleteflag` | tinyint | Признак удаления/увольнения | 0 |

**`bm_PersonnelSecurity`** — Права сотрудников на объекты безопасности (матрица доступа).  
*Строк: 1 402.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1402 |
| `PersonID` | bigint | Сотрудник → personnel.personid (FK не объявлен) | 17 |
| `ObjectID` | bigint | Объект → bm_SecurityObjects.ID (FK) | 25 |
| `IsUse` | int | Право выдано | 1 |

**`bm_JournalSessions`** — Журнал сессий и событий приложения (действия пользователей, ошибки).  
*Строк: 174 072.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 174072 |
| `Type` | varchar(100) | Тип события | Вход в систему |
| `Message` | varchar(max) | Текст события | Успешная авторизация |
| `IsError` | int | Признак ошибки | 0 |
| `DateAdd` | datetime | Дата события | 2026-09-12 09:00:00 |
| `UserAdd` | varchar(50) | Пользователь (текст) | ivanov |
| `PersonID` | bigint | Сотрудник → personnel.personid (FK не объявлен) | 17 |

#### Связанные таблицы

**`securityaccess`** — Справочник уровней доступа.  
*Строк: 4.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `securityaccessid` | int | Код (PK) | 2 |
| `description` | varchar(30) | Наименование | Менеджер |

**`bm_SecurityObjects`** — Справочник объектов безопасности (формы, операции).  
*Строк: 214.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 25 |
| `ParentSystem` | varchar(50) | Система/модуль | Barnet |
| `SecurityGroup` | varchar(100) | Группа | Склад |
| `ObjectName` | varchar(250) | Системное имя | StorageDocsEdit |
| `Description` | varchar(max) | Описание | Редактирование складских документов |

**`bm_SecurityObjects_Info`** — Параметры объектов безопасности (ключ-значение).  
*Строк: 1 570.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1570 |
| `ParentID` | bigint | Объект → bm_SecurityObjects.ID (FK) | 25 |
| `KeyName` | varchar(50) | Ключ | MaxDiscount |
| `KeyValue` | varchar(max) | Значение | 10 |
| `ManagerID` | bigint | Менеджер | 3 |

**`bm_BonusHistory`** — История начисления/списания бонусов по чекам.  
*Строк: 44 866.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 44866 |
| `ClientID` | bigint | Клиент → clients.id (FK не объявлен) | 120 |
| `ActionName` | varchar(100) | Тип действия | Начисление |
| `BonusValue` | numeric | Сумма бонусов | 35.00 |
| `Period` | datetime | Дата | 2026-09-12 21:15:00 |
| `PersonID` | int | Сотрудник → personnel.personid (FK) | 17 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 55012 |
| `ShiftID` | bigint | Смена → bm_ShiftsOperations.ID | 1 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 4 |
| `Amount` | numeric | Сумма документа | 25400.00 |
| `DateAdd` | datetime | Дата создания | 2026-09-12 09:55:00 |
| `UserAdd` | varchar(150) | Пользователь-автор (текст) | ivanov |
| `PersonID` | bigint | Сотрудник-автор → personnel.personid (FK не объявлен) | 17 |

**`journal`** — Журнал продаж POS: одна строка = одна позиция чека (57 колонок, значимые перечислены).  
*Строк: 225 681.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `transnumber` | bigint | Сквозной код строки (PK/уникален; на него ссылается bm_Journal_Details.SourceID) | 5000123 |
| `receiptn` | numeric | Номер чека | 10452 |
| `dater` | datetime | Дата и время операции | 2026-09-12 21:14:05 |
| `amount` | numeric | Сумма строки | 700.00 |
| `discountamount` | numeric | Сумма скидки | 35.00 |
| `loginid` | varchar(13) | Код кассира/официанта (текст) | 17 |
| `flagrefund` | tinyint | Признак возврата | 0 |
| `ManagerName` | varchar(255) | Менеджер, подтвердивший операцию | Петров П. |

**`wastemessages`** — Сообщения о списаниях/отменах позиций в чеках (кто, когда, почему).  
*Строк: 3 582.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 3582 |
| `receiptn` | numeric | Номер чека | 10452 |
| `dater` | datetime | Дата | 2026-09-12 21:30:00 |
| `loginid` | varchar(13) | Кто отменил | 17 |
| `amount` | numeric | Сумма | 350.00 |
| `managerid` | varchar(13) | Менеджер, подтвердивший | 3 |
| `reason` | varchar(255) | Причина (текст) | Ошибка официанта |

**`bm_ShiftsOperations`** — Кассовые смены (в БД одна запись).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 1 |
| `ShiftNumber` | varchar(50) | Номер смены | 2026-001 |
| `Amount` | numeric | Выручка смены | 45000.00 |
| `DateAdd` | datetime | Открытие | 2026-09-12 09:00:00 |
| `PersonalID` | bigint | Сотрудник → personnel.personid (FK не объявлен) | 17 |

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
| `ID` | bigint | Код (PK) | 88 |
| `CalcPeriod` | varchar(255) | Период расчёта | 2026-09 |
| `TicketNumber` | bigint | Номер чека | 10452 |
| `Errors` | varchar(max) | Текст ошибки | Нет |
| `PersonnelID` | bigint | Сотрудник → personnel.personid | 17 |


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
| `id` | bigint | Суррогатный код (PK) | 812 |
| `productid` | varchar(16) | Бизнес-код товара (используется в journal.id) | C0042 |
| `description` | varchar(255) | Наименование | Мохито |
| `CategoryID` | bigint | Категория → category.id | 12 |
| `onhand` | numeric | Текущий остаток | 24.000 |
| `onhandg` | numeric | Остаток в граммах/мл (альтернативная единица) | 24000 |
| `minstockrate` | numeric | Неснижаемый остаток | 5.000 |
| `minfororder` | numeric | Минимум для заказа | 6.000 |
| `lastreceived` | datetime | Дата последнего прихода | 2026-09-10 00:00:00 |
| `lastsold` | datetime | Дата последней продажи | 2026-09-12 00:00:00 |
| `closingcount` | numeric | Результат последней инвентаризации | 23.000 |
| `closingcountdate` | datetime | Дата последней инвентаризации | 2026-08-31 00:00:00 |
| `IsUse` | int | Признак «используется» | 1 |

**`bm_StorageOperations`** — Складские движения (позиции складских документов): приход, расход, списание и т.д.  
*Строк: 1 031 198.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки движения (PK) | 1031198 |
| `DocumentID` | bigint | Документ-основание → bm_JournalBarnetDocs.ID | 55012 |
| `OperationID` | bigint | Вид операции → bm_StorageOperationsType.ID | 1 |
| `ProductID` | bigint | Товар/ингредиент → product.id | 812 |
| `StorageID` | bigint | Склад → storages.id | 1 |
| `Quantity` | numeric | Количество (в базовых единицах) | 12.000 |
| `Rest` | numeric | Остаток после операции | 48.500 |
| `Amount` | numeric | Сумма строки | 5040.00 |
| `ReasonID` | bigint | Причина списания → bm_ReasonDebit.ID (FK не объявлен) | 3 |
| `DateAdd` | datetime | Дата добавления записи | 2026-09-12 10:15:00 |

**`stockperiod`** — Остатки и обороты по товарам за период (открытие/приход/расход/закрытие).  
*Строк: 56.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 56 |
| `storeid` | int | Точка/склад | 1 |
| `productid` | varchar(16) | Код товара = product.productid | C0042 |
| `quantityopen` | numeric | Остаток на начало | 20.000 |
| `quantityin` | numeric | Приход | 30.000 |
| `quantityout` | numeric | Расход | 26.000 |
| `quantityclose` | numeric | Остаток на конец | 24.000 |
| `datestart` | datetime | Начало периода | 2026-09-01 00:00:00 |
| `datefinish` | datetime | Конец периода | 2026-09-30 23:59:59 |

#### Связанные таблицы

**`bm_StorageOperationsType`** — Справочник видов складских операций; Factor задаёт знак (+1 приход / −1 расход).  
*Строк: 5.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код вида операции (PK) | 1 |
| `Description` | varchar(max) | Наименование операции | Приход от поставщика |
| `Factor` | int | Множитель остатка: +1 или −1 | 1 |

**`bm_StorageOperations_Table`** — Табличная часть складских операций (с клиентом/торг. агентом, скидкой). Назначение выведено из структуры колонок (клиент, торговый агент, скидка) — вероятно, отгрузка/реализация; требует подтверждения по данным.  
*Строк: 30 801.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код строки (PK) | 30801 |
| `DocumentID` | bigint | Документ → bm_JournalBarnetDocs.ID | 55100 |
| `OperationID` | bigint | Вид операции → bm_StorageOperationsType.ID | 2 |
| `StorageID` | bigint | Склад → storages.id | 1 |
| `ProductID` | bigint | Товар → product.id | 812 |
| `Quantity` | numeric | Количество | 2.000 |
| `Rest` | numeric | Остаток после операции | 10.000 |
| `ReasonID` | bigint | Причина → bm_ReasonDebit.ID | 0 |
| `DateAdd` | datetime | Дата записи | 2026-09-12 21:20:00 |

**`storages`** — Склады (в БД — одна запись).  
*Строк: 1.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код склада (PK) | 1 |
| `description` | varchar(255) | Наименование склада | Основной склад |
| `ResponsibleID` | int | Ответственный сотрудник → personnel.personid | 17 |

**`category`** — Справочник категорий номенклатуры (дерево).  
*Строк: 158.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 12 |
| `description` | varchar(255) | Наименование | Коктейли |
| `StorageID` | int | Склад по умолчанию → storages.id (FK не объявлен) | 1 |

**`size`** — Справочник единиц/порций.  
*Строк: 78.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код (PK) | 5 |
| `description` | varchar(255) | Наименование | Порция 50 мл |

**`bm_ReasonDebit`** — Справочник причин списания (иерархия).  
*Строк: 47.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код причины (PK) | 3 |
| `ParentID` | bigint | Родительская причина | 1 |
| `Description` | varchar(255) | Наименование причины | Бой посуды / порча |

**`wastemessages`** — Сообщения о списаниях/отменах позиций в чеках (кто, когда, почему).  
*Строк: 3 582.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 3582 |
| `productid` | varchar(16) | Код товара = product.productid | C0042 |
| `dater` | datetime | Дата | 2026-09-12 21:30:00 |
| `quantity` | numeric | Количество | 1.000 |
| `amount` | numeric | Сумма | 350.00 |
| `reason` | varchar(255) | Причина (текст) | Ошибка официанта |

**`beginperiod`** — Даты начала учётных периодов.  
*Строк: 23.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `id` | bigint | Код (PK) | 23 |
| `datestart` | datetime | Дата начала периода | 2026-09-01 00:00:00 |

**`bm_JournalBarnetDocs`** — Шапки документов системы Barnet (накладные, акты, прайс-листы, чеки-основания) — единый реестр документов.  
*Строк: 55 149.*

| Колонка | Тип | Назначение | Пример данных |
|---|---|---|---|
| `ID` | bigint | Код документа (PK) | 55012 |
| `DocumentTypeID` | bigint | Тип документа → bm_JournalTypeDocuments.ID | 4 |
| `Period` | datetime | Дата документа | 2026-09-12 |

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

