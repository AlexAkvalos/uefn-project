# 05. Технологии UEFN (актуальный обзор)

Обзор всех ключевых технологий и систем UEFN по состоянию на сезоны 38–39 (конец 2025 — начало 2026).
Составлено по официальным релиз-ноутам и документации Epic Games.

---

## 🧩 Scene Graph (граф сцены) — новая архитектура

Самое важное направление развития UEFN. Scene Graph — это **entity-component система**,
которая постепенно заменяет старую модель «актор + устройство».

- **Entity (сущность)** — базовый объект сцены. С версии 39.00 даже `agent` (игрок) является подклассом `entity`.
- **Component (компонент)** — кусочек данных/поведения, который вешается на сущность
  (например, `FortPhysics`, меш, кастомный Verse-компонент).
- **Prefab (префаб)** — переиспользуемая иерархия сущностей с компонентами; редактируется в **Prefab Editor**.
- **Verse-компоненты** — можно писать собственные компоненты на Verse и навешивать на сущности.

Зачем: модульность, переиспользование, более «движковый» (как в Unreal) подход вместо нагромождения устройств.

> ⚠️ `Scene Events` и `Custom Items` пока **экспериментальные** — см. известные проблемы в релиз-ноутах 39.00.

---

## 📝 Verse — язык программирования

Основной язык логики UEFN. Подробности — в [02-verse-basics.md](02-verse-basics.md) и [03-devices.md](03-devices.md).

Свежие возможности API:
- **Physics Verse API** — у `fort_character` и `creative_prop` появились методы для скорости,
  массы, импульсов, сил и моментов (linear/angular velocity, impulse, force, torque).
- **Spawner API** — спавн NPC/Wildlife/Guard/Creature в заданной точке; правка Damage/Speed/Health в рантайме.
- **HUD Controller (Verse)** — управление видимостью элементов HUD.
- **In-Island Transactions API** — покупки внутри острова прямо из Verse.

---

## 💰 In-Island Transactions (покупки внутри острова)

Монетизация: продажа предметов и офферов игрокам прямо на острове.

- Описываются как **products** и **offers** в Verse.
- Флаг `ConsequentialToGameplay` обязателен для предметов, дающих игровое преимущество
  (требование Developer Rules 4.4.12).
- Ограничения: `GetMinPurchaseAge`, `RestrictDirectPromptsToPurchase`, `RestrictPaidRandomItem`.
- Публикация покупок открылась **9 января 2026**.
- Метрики — в **Creator Portal → Monetization**.

---

## 🖥️ Кастомный UI (UMG + Verse)

UEFN позволяет строить полностью собственный интерфейс.

- **`player_ui`** — точка входа для добавления виджетов конкретному игроку (`SetFocus`, и т.д.).
- **UMG Verse Class Editor** — создание UMG-классов с Verse-полями; поддержка `color`/`color_alpha`.
- **MVVM** — привязка данных к виджетам (Model-View-ViewModel), автоконвертация биндингов из Details.
- **Кастомные кнопки на Verse**, UI, управляемый данными Verse, **кастомные HUD для транспорта**
  (спидометры/датчики через UI-материал + Vehicle Verse API).
- Шаблон **User Interfaces Feature Example** содержит готовые примеры.

---

## 🤖 NPC и AI (через Scene Graph)

Новый подход к ИИ — через компоненты Scene Graph (добавляются на сущность NPC,
доступную через `npc_behavior.GetEntity[]` или `fort_character.GetEntity[]`):

| Компонент | Назначение |
| --- | --- |
| `npc_actions_component` | базовые движения и фокус NPC (заменяет `navigable`/`focusable`) |
| `guard_actions_component` | продвинутые действия Стражей: атака, прыжки, воскрешение (заменяет `leashable`) |
| `npc_awareness_component` | мониторинг обнаруженных целей — основа реактивного ИИ |
| `guard_awareness_component` | для Стражей: цели, препятствия, уровень тревоги |

Плюс системы **Conversations** (диалоги NPC) и **Creature/Guard/Wildlife Spawner**.

---

## ⚙️ Физика

- **Physics Verse API** (см. выше) — программные импульсы, силы, скорости.
- **FortPhysics** — Scene Graph-компонент физики; быстро добавляется инструментом **Add Physics**.
- **Chaos Visual Debugger (CVD)** — захват и воспроизведение физической сцены для отладки
  (коллизии, queries, геометрия). Меню: **Tools → Debug → Chaos Visual Debugger**.

---

## 📱 Мобильная разработка

- **Mobile Preview** — запуск сессии в мобильном режиме прямо из UEFN (соотношения сторон,
  настройки масштабируемости) для оценки качества арта, света, UI на мобилках.
- **Input Trigger device** — кастомные сенсорные кнопки, раскладки, иконки,
  подписка на направленный ввод (виртуальный джойстик).

---

## 🛠️ Инструменты оптимизации и профилирования

- **Fortnite Tools Mode** (меню **Select Mode → Fortnite Tools**):
  - **Add Physics** — массовое добавление/удаление физики.
  - **Optimize Textures** — проверка и советы по текстурам (особенно для мобилок).
  - **Optimize Static Mesh** — то же для статик-мешей.
  - **Find Overlapping** — поиск пересекающихся объектов.
- **Spatial Profiler** — анализ нагрузки по острову, цветовые пороги (зелёный/жёлтый/красный).
- **Memory Diagnostics** — контроль памяти (важно из-за лимитов платформ).
- **Debug Commands** (бета-меню): Change Time of Day, Change World Speed, Infinite Building Resources,
  Print Owned Products, Toggle FN HUD Visibility и др.

---

## 💾 Персистентность (сохранения)

- **Save device** и **Verse persistence** — сохранение прогресса между сессиями.
- Поведение редактирования: **Persistence Behavior: Edit Session** (Import Live Data и т.д.).
- Примеры: лидерборды, статистика игроков, логика раундов.

---

## 🎬 Графика и контент

| Система | Что это |
| --- | --- |
| **Sequencer / Cinematics** | кат-сцены, кинематика |
| **Materials** | редактор материалов (как в UE) |
| **Niagara (VFX)** | визуальные эффекты |
| **Landscape / Environments** | ландшафты, edit layers, weight blending |
| **Modeling** | моделирование мешей прямо в редакторе |
| **MetaHumans** | реалистичные персонажи |
| **Lighting / Lumen** | освещение, глобальное освещение Lumen |
| **Audio / Patchwork** | звук и музыкальная система Patchwork |
| **Galleries / Prefabs** | готовые наборы ассетов (напр. Brutal Bastion, Pacific Break) |

---

## 🌐 Экосистема: публикация и Discover

- **Creator Portal** (create.fortnite.com) — публикация, монетизация, аналитика, аттрибуция.
- **Discover** — система рекомендаций островов (учитывает соц-метрики: приглашения, время в пати).
- **Epic's Picks** — с v39.00 обязательна **аттрибуция** кастомных ассетов/музыки.
- **Unreal Revision Control (URC)** — контроль версий ассетов внутри UEFN.
- **Fortnite Developer Agreement** — обновлённое соглашение разработчика (обязательно принять).

---

## Источники

- Документация UEFN: https://dev.epicgames.com/documentation/en-us/uefn/unreal-editor-for-fortnite-documentation
- Verse API Reference: https://dev.epicgames.com/documentation/en-us/uefn/verse-api
- Релиз-ноуты (актуальные): https://dev.epicgames.com/documentation/en-us/fortnite/fortnite-ecosystem-updates-and-release-notes
- Scene Graph: https://dev.epicgames.com/documentation/en-us/fortnite/scene-graph-in-unreal-editor-for-fortnite
- In-Island Transactions: https://dev.epicgames.com/documentation/en-us/fortnite/creating-items-and-offers-in-fortnite
