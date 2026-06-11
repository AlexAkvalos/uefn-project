# uefn-project

Проект для разработки на **UEFN (Unreal Editor for Fortnite)** с использованием языка **Verse**.

Репозиторий содержит структуру под Verse-код, примеры устройств (devices) и заметки по документации Epic Games.

---

## 📦 Что это

[UEFN](https://dev.epicgames.com/documentation/en-us/uefn/unreal-editor-for-fortnite-documentation) — редактор от Epic Games для создания островов и игровых режимов внутри Fortnite. Логика пишется на языке **Verse**.

Этот репозиторий — рабочее пространство для:

- хранения и версионирования Verse-кода (`.verse`);
- примеров устройств, написанных на Verse (Verse-authored devices);
- заметок и шпаргалок по документации Epic.

> ⚠️ Сами ассеты UEFN (`.uasset`, `.umap`), кэши и сборочные папки **не** хранятся в git — см. [`.gitignore`](.gitignore). В репозитории живёт прежде всего **код**.

---

## 🗂️ Структура репозитория

```
uefn-project/
├── README.md                  ← этот файл
├── LICENSE
├── .gitignore                 ← игнор для UEFN/Unreal (кэши, Intermediate, Saved…)
├── .editorconfig
├── docs/                      ← заметки и шпаргалки на русском
│   ├── 01-getting-started.md  ← с чего начать
│   ├── 02-verse-basics.md     ← основы языка Verse
│   ├── 03-devices.md          ← устройства и события
│   ├── 04-project-structure.md← как устроен проект UEFN на диске
│   ├── 05-latest-tech.md      ← обзор всех технологий UEFN (Scene Graph, физика, UI, AI…)
│   ├── 06-whats-new.md        ← что нового в сезонах 38–39
│   ├── 07-scene-graph.md      ← устройства vs компоненты (entity-component)
│   ├── 08-learning-resources.md← YouTube, курсы, сообщества, монетизация
│   ├── 09-cool-features.md    ← классные фишки и приёмы (из YouTube и X)
│   ├── 10-fresh-2026.md       ← 🔥 самое свежее: релизы v40–v41, AI-ассистент, breaking changes
│   ├── 11-future-ue6-roadmap.md← Unreal Engine 6, роадмап, Creator Economy 2.0
│   ├── 12-advanced-patterns.md← продвинутые паттерны Verse (concurrency, persistence, raycast)
│   ├── 13-ui-hud.md           ← топовый HUD и UI на Verse (UMG)
│   ├── 14-device-best-practices.md← как делать устройства правильно (архитектура, события, стиль)
│   ├── 15-data-and-persistence.md← данные: типы, коллекции, сохранения, статы, аналитика
│   ├── 16-custom-weapons.md   ← кастомное оружие (Custom Weapon Templates, v41.00)
│   ├── 17-custom-items-inventory.md← Custom Items & Inventory (компоненты, крафт, UI)
│   ├── 18-ai-npc-scene-graph.md← AI/NPC через Scene Graph (actions/awareness, спавн)
│   ├── 19-steal-a-brainrot.md ← жанр «Steal a Brainrot» (tycoon + кража юнитов)
│   └── 20-props-cinematics-npc.md← пропы, синематики, NPC с ними
└── verse/                     ← исходный Verse-код
    ├── devices/               ← устройства (creative_device)
    │   ├── hello_world_device.verse
    │   ├── button_interaction_device.verse
    │   ├── round_manager_device.verse
    │   ├── pickup_device.verse        ← пример: single-responsibility + событие
    │   ├── score_manager_device.verse ← пример: менеджер (правила + состояние)
    │   ├── weapon_loadout_device.verse← пример: выдача оружия через Item Granter
    │   ├── ping_pong_mover.verse      ← пример: движение пропа MoveTo в цикле
    │   └── cinematic_trigger.verse    ← пример: кинематика по триггеру + скрытие HUD
    ├── components/            ← компоненты Scene Graph (новый подход)
    │   ├── disappear_on_loop_component.verse
    │   └── coin_pickup_component.verse  ← пример: custom item + подбор (Custom Items)
    ├── ui/                    ← интерфейс на Verse (UMG)
    │   └── custom_hud_device.verse
    ├── ai/                    ← поведение NPC (Scene Graph AI)
    │   └── reactive_guard_behavior.verse
    ├── persistence/          ← сохранения между сессиями
    │   └── player_progress.verse   ← пример: прогресс игрока с версионированием
    ├── games/                ← каркасы игровых режимов
    │   └── brainrot_income.verse   ← каркас экономики «Steal a Brainrot»
    └── utils/
        └── log.verse          ← вспомогательный канал логирования
```

### Куда класть Verse-файлы внутри UEFN

UEFN создаёт Verse-файлы внутри плагина проекта:

```
<МойПроект>/
└── Plugins/
    └── <МойПроект>/
        └── Content/
            └── *.verse        ← сюда UEFN кладёт твои устройства
```

Файлы из папки [`verse/`](verse/) этого репозитория — это **эталонные примеры**. Их код можно копировать в `.verse`-файлы, созданные через **Verse → Verse Explorer → Add new Verse file** в UEFN.

---

## 🚀 Быстрый старт

1. Установи **UEFN** через [Epic Games Launcher](https://store.epicgames.com/ru/download).
2. Установи **Visual Studio Code** + официальное расширение Verse (ставится автоматически при запуске UEFN).
3. Создай проект в UEFN (например, из шаблона **Verse Device** в Feature Examples).
4. В **Verse → Verse Explorer** добавь новый Verse-файл и вставь код из [`verse/devices/hello_world_device.verse`](verse/devices/hello_world_device.verse).
5. **Verse → Build Verse Code**, перетащи устройство на уровень, нажми **Launch Session**.
6. В логе появится `Hello, world!`.

Подробнее — в [`docs/01-getting-started.md`](docs/01-getting-started.md).

> 🆕 Обзор актуальных технологий UEFN (Scene Graph, физика на Verse, кастомный UI, AI, монетизация) — в [`docs/05-latest-tech.md`](docs/05-latest-tech.md). Что нового по сезонам — в [`docs/06-whats-new.md`](docs/06-whats-new.md). Архитектура entity-component — в [`docs/07-scene-graph.md`](docs/07-scene-graph.md). Видео, курсы и сообщества — в [`docs/08-learning-resources.md`](docs/08-learning-resources.md). Классные фишки и приёмы топ-разработчиков — в [`docs/09-cool-features.md`](docs/09-cool-features.md).

> 🔥 **Самое свежее (2026):** релизы v40–v41 и breaking changes — [`docs/10-fresh-2026.md`](docs/10-fresh-2026.md) · Unreal Engine 6 и роадмап — [`docs/11-future-ue6-roadmap.md`](docs/11-future-ue6-roadmap.md) · продвинутые паттерны Verse — [`docs/12-advanced-patterns.md`](docs/12-advanced-patterns.md) · топовый HUD и UI на Verse — [`docs/13-ui-hud.md`](docs/13-ui-hud.md) · как делать устройства правильно — [`docs/14-device-best-practices.md`](docs/14-device-best-practices.md) · данные и сохранения — [`docs/15-data-and-persistence.md`](docs/15-data-and-persistence.md) · кастомное оружие — [`docs/16-custom-weapons.md`](docs/16-custom-weapons.md) · Custom Items & Inventory — [`docs/17-custom-items-inventory.md`](docs/17-custom-items-inventory.md) · AI/NPC через Scene Graph — [`docs/18-ai-npc-scene-graph.md`](docs/18-ai-npc-scene-graph.md) · жанр «Steal a Brainrot» — [`docs/19-steal-a-brainrot.md`](docs/19-steal-a-brainrot.md) · пропы/синематики/NPC — [`docs/20-props-cinematics-npc.md`](docs/20-props-cinematics-npc.md).

---

## 📚 Полезные ссылки (официальная документация Epic)

| Тема | Ссылка |
| --- | --- |
| Документация UEFN | https://dev.epicgames.com/documentation/en-us/uefn/unreal-editor-for-fortnite-documentation |
| Язык Verse — старт | https://dev.epicgames.com/documentation/en-us/fortnite/verse-language-get-started |
| Verse API Reference | https://dev.epicgames.com/documentation/en-us/uefn/verse-api |
| Создание устройства на Verse | https://dev.epicgames.com/documentation/en-us/fortnite/create-your-own-device-using-verse-in-unreal-editor-for-fortnite |
| Editable-свойства | https://dev.epicgames.com/documentation/en-us/fortnite/editable-properties-in-verse |
| Verse Glossary | https://dev.epicgames.com/documentation/en-us/fortnite/verse-glossary |
| Релиз-ноуты Fortnite Ecosystem | https://dev.epicgames.com/documentation/en-us/fortnite/fortnite-ecosystem-updates-and-release-notes |

---

## 📝 Лицензия

[MIT](LICENSE). Код Verse в этом репозитории — учебные примеры. Fortnite, UEFN и Verse — товарные знаки Epic Games, Inc.
