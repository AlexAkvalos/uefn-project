# 17. Custom Items & Inventory (глубокий разбор)

Система кастомных предметов и инвентарей на **Scene Graph**. Вышла из беты в v40.20 (можно публиковать), актуальна в v41.00.
Это фундамент, на котором построены и Custom Weapon Templates (см. [16-custom-weapons.md](16-custom-weapons.md)).

Рабочий пример: [`../verse/components/coin_pickup_component.verse`](../verse/components/coin_pickup_component.verse).

---

## 1. Архитектура

- Всё построено на **Scene Graph**: **Entity** (сущность-контейнер) + **Component** (поведение).
- **Предмет = сущность с `item_component`.** **Инвентарь = сущность с `inventory_component`.** Больше ничего — это обычные сущности, отличающиеся компонентом.
- Предмет в каждый момент лежит **только в одном инвентаре**.
- Включается в **Project Settings** (тумблер Custom Items and Inventory). Нужны Scene Graph + Verse.

### Модель инвентаря (почему корень не хранит предметы)
- У каждого игрока есть **Inventory Root**.
- **Корень сам предметы НЕ принимает** — он только родитель для подынвентарей.
- **Subinventory** — дочерний инвентарь под родителем. Родитель «видит» все инвентари ниже.
  Пример: `Inventory Root → Backpack → Money Pouch`.
- Поэтому **у игрока должна быть минимум одна подынвентарь**, а пикапы зовут
  `AddItemDistribute()` на корне — он спускается до подходящей подынвентари.

### Версии
- **v39.30** — Experimental; старый `fort_item_pickup_component` устарел → `interactable_component`.
- **v40.20** — Beta, **публикуемо**; переименованы компоненты (ниже); неймспейсы `/Fortnite.com/Items`, `/Fortnite.com/Weapons`.
- **v41.00** — + Weapon Templates, стандартный паттерн Verse Persistence для предметов.

---

## 2. Компоненты (ядро)

Неймспейсы:
```verse
using { /Verse.org/SceneGraph }          # entity/component, interactable_component
using { /Verse.org/Simulation }          # события, агенты
using { /UnrealEngine.com/Itemization }  # item_component, inventory_component…
using { /Fortnite.com/Items }            # встроенные предметы Fortnite (v40.20+)
using { /Fortnite.com/Weapons }          # встроенное оружие (v40.20+)
```

> ⚠️ **Переименования v40.20:** `item_details_component → description_component`,
> `item_icon_component → icon_component`. Плюс новые **Rarity** и **Stacking** компоненты.
> Старые туториалы используют старые имена.

| Компонент | Назначение |
| --- | --- |
| **`item_component`** | делает сущность предметом; поля `Categories`; методы `Equip()`/`Unequip()`/`IsEquipped[]`/`GetParentInventory[]`; события `ChangeEquippedEvent`, `ChangeInventoryEvent` |
| **`inventory_component`** | контейнер; методы (ниже); события `AddItemEvent`/`RemoveItemEvent`/`EquipItemEvent`/`UnequipItemEvent` |
| **`description_component`** | имя/описание предмета (для UI и подсказок) |
| **`icon_component`** | 2D-иконка для HUD/инвентаря (поле Icon = текстура) |
| **`stacking_component`** | стаки/слияние (count/max) |
| **`rarity_component`** | редкость (Common…Mythic) для UI и сортировки |
| **`interactable_component`** | база для взаимодействий/пикапов (замена `fort_item_pickup_component`) |

**Готовые инвентари Fortnite** (подклассы `fort_inventory_component`, с дефолтным UI):
`fort_inventory_weapon_hotbar_component`, `…_build_hotbar_…`, `…_resources_…`, `…_ammo_…`,
`fort_inventory_currencies_component` (валюты — точка входа для экономики) и др.

### Подкласс предмета
```verse
coin_item_component := class(item_component):
    Value : int = 1
```

---

## 3. Ключевые Verse API

**Методы `inventory_component`:**
- `AddItem()` — добавить в ЭТОТ инвентарь.
- `AddItemDistribute()` — добавить сюда **или в любую подынвентарь**, которая примет (зови на корне игрока).
- `RemoveItem()` — удалить.
- `GetItems()` — предметы только этого инвентаря; `FindItems()` — рекурсивно по всем потомкам.
- `GetInventories()` / `FindInventories()` — подынвентари.
- `GetEquippedItems()` — экипированные.

**Получить корень игрока** (verbatim из официального туториала):
```verse
GetInventoryRoot(Agent:agent)<decides><transacts>:inventory_component =
    Inventory := (for (I : Agent.FindDescendantComponents(inventory_component)) { I })[0]
```

**Выдать предмет (каноничный вызов пикапа):**
```verse
if (PlayerInv := GetInventoryRoot[Agent]):
    if (PlayerInv.AddItemDistribute(Entity).GetSuccess[]):
        # предмет принят какой-то подынвентарью
```

**События инвентаря:**
```verse
Inv.AddItemEvent.Subscribe(OnItemAdded)
Inv.RemoveItemEvent.Subscribe(OnItemRemoved)
```

**Правила приёма (rules engine):** при добавлении/удалении инвентарь получает
`add_item_query_event` / `remove_item_query_event`; ответ на него решает, пройдёт ли `AddItem`/`RemoveItem`.
Так строят правила: принимать только нужную `item_category`, лимит предметов, запрет удалять последний,
вытеснение низкоприоритетных, «только один предмет». (Если предметы молча не добавляются — это query-ответ их отклоняет.)

---

## 4. Крафт и экономики

Отдельного «crafting_component» нет — собираешь из примитивов:
- **Стаки/ресурсы:** stacking + `fort_inventory_resources_component` (материалы сливаются в счётчики).
- **Валюты:** `fort_inventory_currencies_component`; тратишь через `RemoveItem()` валюты + добавление товара.
- **Крафт = потребить вход → создать выход:** читаешь `FindItems()`, проверяешь количество/категории,
  `RemoveItem()` входы, `AddItemDistribute()` новый предмет.
- **Расходники:** на использовании уменьшаешь стак (или `RemoveItem()` на 0) и применяешь эффект.

```verse
# 2 монеты -> 1 гем
TryCraftGem(PlayerInv : inventory_component):void=
    Coins := for (I : PlayerInv.FindItems(), C := I.GetComponent[coin_item_component]) { I }
    if (Coins.Length >= 2):
        if (PlayerInv.RemoveItem(Coins[0]) and PlayerInv.RemoveItem(Coins[1])):
            if (Gem := MakeGemEntity[]):
                PlayerInv.AddItemDistribute(Gem)
```

---

## 5. Кастомный UI инвентаря

Предметы не рисуются в кастомном UI сами — связываешь через **Verse + UMG** (см. [13-ui-hud.md](13-ui-hud.md)):
- читаешь данные из компонентов предмета: `icon_component` (иконка), `description_component` (имя/описание),
  `rarity_component` (цвет/рамка), stacking (количество);
- наполняешь, итерируя `Inv.GetItems()`/`FindItems()`; обновляешь по `AddItemEvent`/`RemoveItemEvent`;
- хочешь стандартный вид Fortnite — наследуй `fort_inventory_component` и `fort_inventory_*_hotbar_*` (дефолтный UI бесплатно).

---

## 6. Другие области

- **Пикапы/интерактивы:** современный путь — подкласс `interactable_component`, зовущий `AddItemDistribute()`.
  Есть готовый `fort_item_pickup_interactable_component`.
- **Дроп:** удалить из инвентаря + перепривязать сущность в мир (с мешем).
- **Оружие (v41):** кастомное оружие — item-сущности под `/Fortnite.com/Weapons`; встроенные предметы именуются
  `[Имя]_[Product]_[Version]_[Rarity]` (напр. `CombatAssaultRifle_BR_Ch7S1_Common`).
- **Персистентность:** кастомные предметы сохраняются стандартной **Verse Persistence**
  (player-keyed `weak_map`, пересоздание состояния предметов при заходе). См. [15-data-and-persistence.md](15-data-and-persistence.md).

---

## 7. Лимиты, гочи, best practices

- **Корень не хранит предметы** — дай игроку ≥1 подынвентарь и зови `AddItemDistribute()` на корне (не `AddItem()`).
- **Переименования v40.20** — старые имена компонентов в старых туториалах.
- **Beta, но публикуемо** (с v40.20; раньше Experimental — нельзя было публиковать).
- **Конфликтующие Island Settings** (поведение не определено при включённой фиче): Auto Pickup, Infinite Gold,
  Infinite Reserve Energy, Show Gold Resource Count, Allow Item Pickup, Hide Build Resource, Infinite Durability,
  Keep Dropped Items Between Rounds — проверь их, если заменяешь дефолтный инвентарь.
- **Правила идут через query-события** — и на добавление, и на удаление.
- **Один инвентарь на предмет** — перемещение = remove + add.
- **Best practices:** предметы как переиспользуемые префабы; типизированные подклассы `item_component`/`inventory_component`;
  подписка на события для UI вместо поллинга; фильтры по категориям на подынвентарях; `fort_inventory_*` для дефолтного UI.

---

## 8. Источники
- Hub — Custom Items and Inventories with Scene Graph: https://dev.epicgames.com/documentation/fortnite/custom-items-and-inventories-with-scene-graph-in-uefn
- Overview: https://dev.epicgames.com/documentation/fortnite/custom-items-and-inventory-overview-in-fortnite
- Item Component: https://dev.epicgames.com/documentation/en-us/fortnite/item-component-in-fortnite
- Inventory Component: https://dev.epicgames.com/documentation/fortnite/inventory-component-in-fortnite
- Create an Item Pickup Interactable Component: https://dev.epicgames.com/documentation/fortnite/create-an-item-pickup-interactable-component-in-fortnite
- Create a Keycard with the Prefab Editor: https://dev.epicgames.com/documentation/fortnite/create-a-keycard-with-the-prefab-editor-in-fortnite
- v40.20 release notes: https://dev.epicgames.com/documentation/fortnite/40-20-fortnite-ecosystem-updates-and-release-notes
- Community: How to Make a Custom Inventory System (Verse): https://dev.epicgames.com/community/learning/tutorials/6X13/fortnite-how-to-make-a-custom-inventory-system-in-uefn-verse-tutorial
