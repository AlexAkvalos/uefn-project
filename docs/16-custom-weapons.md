# 16. Кастомное оружие (Custom Weapon Templates, v41.00)

Как создавать собственное оружие в UEFN. Главная фича — **Custom Weapon Templates**, добавлена в v41.00 (июнь 2026).
Рабочий пример выдачи оружия: [`../verse/devices/weapon_loadout_device.verse`](../verse/devices/weapon_loadout_device.verse).

> ⚠️ v41.00 — ранний/бета-релиз фичи. Базовый рескин + 4 стата работают; глубокий контроль
> (анимации, патроны, подтипы) пока отсутствует. Многое будет меняться в патчах v41.x.

---

## Что это

Custom Weapon Templates — фича на базе **Scene Graph**: берёшь готовый шаблон базового оружия Fortnite
и переопределяешь его внешний вид, звук и баланс. Впервые ключевые статы (урон, скорострельность, разброс, отдача)
и визуал/аудио редактируются прямо в редакторе без сложных Verse-обходов.

Концептуально: кастомное оружие = **подкласс базового шаблона** с переопределениями.
Это **Scene Graph entity**, а не creative_device.

## 4 базовых шаблона

| Шаблон | Внутреннее имя | Тип патронов (зафиксирован) |
| --- | --- | --- |
| Pistol | `pistol_template` | Small ammo |
| SMG | `sub_machine_gun_template` | Small ammo |
| Assault Rifle | `assault_rifle_template` | Medium ammo |
| Shotgun | `shotgun_template` | Shells |

---

## Workflow в редакторе (без Verse для базового создания)

1. Открой проект в **UEFN**, убедись что **Scene Graph включён** (Project Settings).
2. Добавь **Entity Prefab** и выбери один из 4 шаблонов оружия.
3. Открой в **Prefab Editor**: Outliner — иерархия, Details — карточки компонентов с переопределениями
   (один компонент данного класса на сущность).
4. Настрой две группы свойств (ниже) → размести/заспавни оружие.

---

## Что можно настроить

**Presentation (визуал + аудио):**
- **Mesh** — модель оружия (пока только **static mesh**, скелетных нет).
- **Effects (VFX)** — вспышка выстрела / эффекты.
- **Sounds** — звук выстрела и перезарядки (только сырые звуки, без Audio Cue).

**Balance (статы):**
- **Damage** (урон)
- **Fire rate** (скорострельность)
- **Spread** (разброс/точность)
- **Recoil** (отдача)

## Чего ПОКА нельзя (v41.00 — фидбэк через день после релиза, может измениться)

- Размер магазина / время перезарядки / дальность — не редактируются.
- Тип патронов — зафиксирован по шаблону.
- Хедшот-множитель — фиксированный **1.5×**.
- Projectile vs hitscan — без переключателя (наследуется от базы).
- Скелетные меши, отдельные модели pickup/держания, кастомные анимации, подтипы (burst/charge/overheat).

**Баги на старте (вероятно пофиксят):** UI магазина показывает оригинальный размер; настройка rarity не применяется (всё Common); хитбокс подбора берётся от модели шаблона (рескин трудно подобрать).

---

## Интеграция с Verse

### ⚠️ Персистентность обязательна
Прямая цитата из v41.00:
> Чтобы сущности (вкл. шаблоны оружия) сохранялись между сессиями, **нужна Verse Persistence**.
> Эти сущности **несовместимы** со старыми способами (Save Point device).

См. [15-data-and-persistence.md](15-data-and-persistence.md) — реализуй и протестируй сохранения перед публикацией.

### Custom Items & Inventory — на чём построено оружие
Шаблоны оружия — это «готовые item-сущности» системы **Custom Items and Inventory** (вышла из беты в v40.20, можно публиковать):
- **`item_component`** — делает сущность предметом (экипировка, категории, события).
- **`inventory_component`** — делает сущность инвентарём-контейнером.
- У каждого игрока есть **Inventory Root** (не хранит предметы напрямую) → нужны **subinventories**.
- Выдача через Verse: **`AddItem()`** (в конкретный инвентарь) и **`AddItemDistribute()`** (подобрать подходящий по иерархии).

> Точные имена компонентов оружия и Verse-неймспейс предметов в релиз-ноутах не задокументированы —
> сверяй в **Verse Explorer / Prefab Editor** своей версии v41.00.

### Классическая выдача оружия (device-based, работает везде)
Стандартный паттерн — **Item Granter device** из `creative_device`:
```verse
@editable Granters : []item_granter_device = array{}

GrantLoadout(Agent : agent, Index : int):void=
    if (Granter := Granters[Index]):
        Granter.GrantItem(Agent)
```
Полный пример — [`weapon_loadout_device.verse`](../verse/devices/weapon_loadout_device.verse).
Смена оружия по элиминации (Gun Game) делается связкой `item_granter_device` + подписка на события элиминации.

> ⚠️ Гоча: общего `WeaponFiredEvent` на персонаже **нет**, «объекта снаряда» Fortnite не отдаёт.
> Надёжно ловить «выстрел/попадание» из Verse сложно — опирайся на события устройств
> (урон/элиминация, триггер-зоны), а не на прямой хук выстрела.

---

## Связанные системы (контекст)

- **Weapon Mods** (геймплейная система BR): Optic / Magazine / Underbarrel / Barrel — перки (отдача, скорость перезарядки, ADS-зум, барабан). Это НЕ авторинг шаблонов.
- **До v41**: «кастомное» оружие фейкали через Item Granter + Verse-хаки статов (mutator/damage-зоны). Контроль статов был очень ограничен.
- **Custom Items beta (v40.20)** — прямой фундамент шаблонов оружия v41.00.

---

## Лимиты, публикация, баланс, best practices

- **Лимиты v41:** только static mesh, патроны зафиксированы, хедшот 1.5×, нет анимаций/подтипов/Audio Cue, ряд багов. Считай фичу бета-качеством.
- **Публикация:** Custom Items & Inventory можно публиковать (с v40.20); оружию нужна **Verse Persistence** (не Save Point). Кастомные меши/звуки — только те, на которые есть права.
- **Баланс:** стартуй от шаблона с нужным TTK/дальностью (projectile/hitscan и патроны наследуются); крути **урон × скорострельность** вместе; хедшот фиксирован 1.5× — балансируй по body-shot DPS; различай ближний/дальний бой через **spread + recoil**.
- **Best practices:** переопределяй через Prefab Editor (не дублируй шаблоны вручную); тестируй подбор (хитбокс); читай persistence-доки перед релизом; имена компонентов/неймспейсы сверяй в Verse Explorer своей версии.

---

## Туториалы и источники

- v41.00 release notes: https://dev.epicgames.com/documentation/fortnite/41-00-fortnite-ecosystem-updates-and-release-notes
- Custom Items and Inventories with Scene Graph: https://dev.epicgames.com/documentation/fortnite/custom-items-and-inventories-with-scene-graph-in-uefn
- Custom Items and Inventory Overview: https://dev.epicgames.com/documentation/fortnite/custom-items-and-inventory-overview-in-fortnite
- Granting Weapons on Eliminations (Verse): https://dev.epicgames.com/documentation/en-us/fortnite/team-elimination-game-5-granting-weapons-on-eliminations-in-verse
- Community: Custom Weapons + Verse Persistence (v41.00): https://forums.unrealengine.com/t/community-tutorial-custom-weapons-verse-persistence-system-uefn-v41-00/2726681
- Фидбэк по лимитам v41.00: https://forums.unrealengine.com/t/feedback-custom-weapons-as-of-a-day-after-release-in-v41-00/2726958
- YouTube (без Verse, v41.00): https://www.youtube.com/watch?v=Uhm3jaTAVE4
