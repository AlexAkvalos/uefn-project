# 00. Индекс-навигатор по документации

Карта всех статей проекта. Это **живой документ** — при добавлении новых статей дописывай строку
в нужный раздел и в «Полный список» ниже.

> 📌 Соглашение: статьи нумеруются `NN-kebab-case.md`, примеры кода лежат в `../verse/<категория>/`.
> Новую статью клади следующим номером и добавляй сюда ссылку.

---

## 🚀 Рекомендованный порядок изучения

**Новичку — по шагам:**
1. [01. С чего начать](01-getting-started.md) — установка, первое устройство
2. [02. Основы Verse](02-verse-basics.md) — синтаксис языка
3. [03. Устройства и события](03-devices.md) — `creative_device`, события
4. [04. Структура проекта](04-project-structure.md) — что на диске, что в git
5. [13. HUD и UI](13-ui-hud.md) — интерфейс на Verse
6. [15. Данные и сохранения](15-data-and-persistence.md) — типы, коллекции, persistence

**Среднему уровню:**
7. [14. Устройства правильно](14-device-best-practices.md) — архитектура, события, стиль
8. [12. Продвинутые паттерны](12-advanced-patterns.md) — concurrency, persistence, raycast
9. [07. Scene Graph](07-scene-graph.md) — entity-component, будущее UEFN
10. [05. Технологии UEFN](05-latest-tech.md) — обзор всех систем

**Продвинутым / по задачам:**
11. [17. Custom Items & Inventory](17-custom-items-inventory.md)
12. [16. Кастомное оружие](16-custom-weapons.md)
13. [18. AI/NPC через Scene Graph](18-ai-npc-scene-graph.md)
14. [20. Пропы, синематики, NPC](20-props-cinematics-npc.md)
15. [19. Жанр «Steal a Brainrot»](19-steal-a-brainrot.md)

---

## 📚 По темам

### Старт и язык
- [01. С чего начать](01-getting-started.md)
- [02. Основы Verse](02-verse-basics.md)
- [04. Структура проекта UEFN](04-project-structure.md)
- [08. Ресурсы для обучения](08-learning-resources.md) — YouTube, курсы, сообщества

### Устройства и архитектура
- [03. Устройства и события](03-devices.md)
- [14. Как делать устройства правильно](14-device-best-practices.md)
- [12. Продвинутые паттерны Verse](12-advanced-patterns.md)

### Scene Graph (новая архитектура)
- [07. Scene Graph: устройства vs компоненты](07-scene-graph.md)
- [18. AI/NPC через Scene Graph](18-ai-npc-scene-graph.md)
- [17. Custom Items & Inventory](17-custom-items-inventory.md)

### Интерфейс и данные
- [13. Топовый HUD и UI на Verse](13-ui-hud.md)
- [15. Данные и сохранения (persistence)](15-data-and-persistence.md)

### Геймплейные системы
- [16. Кастомное оружие (Custom Weapon Templates)](16-custom-weapons.md)
- [17. Custom Items & Inventory](17-custom-items-inventory.md)
- [18. AI/NPC](18-ai-npc-scene-graph.md)
- [20. Пропы, синематики, NPC](20-props-cinematics-npc.md)
- [19. Жанр «Steal a Brainrot»](19-steal-a-brainrot.md)

### Контекст и тренды
- [05. Технологии UEFN (обзор)](05-latest-tech.md)
- [06. Что нового (сезоны 38–39)](06-whats-new.md)
- [09. Классные фишки и приёмы](09-cool-features.md)
- [10. Самое свежее (v40–v41)](10-fresh-2026.md)
- [11. Будущее: UE6 и роадмап](11-future-ue6-roadmap.md)

---

## 📄 Полный список статей

| № | Статья | О чём |
| --- | --- | --- |
| 01 | [getting-started](01-getting-started.md) | установка, первое устройство |
| 02 | [verse-basics](02-verse-basics.md) | основы языка Verse |
| 03 | [devices](03-devices.md) | устройства и события |
| 04 | [project-structure](04-project-structure.md) | структура проекта на диске |
| 05 | [latest-tech](05-latest-tech.md) | обзор всех технологий UEFN |
| 06 | [whats-new](06-whats-new.md) | что нового в сезонах 38–39 |
| 07 | [scene-graph](07-scene-graph.md) | entity-component архитектура |
| 08 | [learning-resources](08-learning-resources.md) | YouTube, курсы, сообщества, монетизация |
| 09 | [cool-features](09-cool-features.md) | фишки и приёмы из YouTube и X |
| 10 | [fresh-2026](10-fresh-2026.md) | релизы v40–v41, AI-ассистент, breaking changes |
| 11 | [future-ue6-roadmap](11-future-ue6-roadmap.md) | Unreal Engine 6, роадмап, Creator Economy 2.0 |
| 12 | [advanced-patterns](12-advanced-patterns.md) | concurrency, persistence, raycast |
| 13 | [ui-hud](13-ui-hud.md) | топовый HUD и UI на Verse (UMG) |
| 14 | [device-best-practices](14-device-best-practices.md) | архитектура устройств, события, стиль |
| 15 | [data-and-persistence](15-data-and-persistence.md) | данные, коллекции, сохранения, статы, аналитика |
| 16 | [custom-weapons](16-custom-weapons.md) | Custom Weapon Templates (v41.00) |
| 17 | [custom-items-inventory](17-custom-items-inventory.md) | Custom Items & Inventory |
| 18 | [ai-npc-scene-graph](18-ai-npc-scene-graph.md) | AI/NPC через Scene Graph |
| 19 | [steal-a-brainrot](19-steal-a-brainrot.md) | жанр tycoon + кража юнитов |
| 20 | [props-cinematics-npc](20-props-cinematics-npc.md) | пропы, синематики, NPC с ними |

---

## 💻 Карта примеров Verse (`../verse/`)

| Файл | Что демонстрирует | Статья |
| --- | --- | --- |
| `devices/hello_world_device.verse` | минимальное устройство | 01, 03 |
| `devices/button_interaction_device.verse` | кнопка + очки, @editable | 03 |
| `devices/round_manager_device.verse` | таймер раунда, loop/Sleep | 03 |
| `devices/pickup_device.verse` | single-responsibility + событие | 14 |
| `devices/score_manager_device.verse` | менеджер (правила + состояние) | 14 |
| `devices/weapon_loadout_device.verse` | выдача оружия (Item Granter) | 16 |
| `devices/ping_pong_mover.verse` | движение пропа `MoveTo` в цикле | 20 |
| `devices/cinematic_trigger.verse` | кинематика + скрытие HUD | 20 |
| `components/disappear_on_loop_component.verse` | компонент Scene Graph | 07 |
| `components/coin_pickup_component.verse` | custom item + подбор | 17 |
| `ui/custom_hud_device.verse` | per-player HUD (canvas/кнопка) | 13 |
| `ai/reactive_guard_behavior.verse` | реактивный страж (awareness+actions) | 18 |
| `persistence/player_progress.verse` | прогресс с версионированием | 15 |
| `games/brainrot_income.verse` | каркас экономики «Steal a Brainrot» | 19 |
| `utils/log.verse` | канал логирования | 02 |

---

## ➕ Как добавить новую статью

1. Создай `docs/NN-название.md` (следующий номер).
2. Добавь строку в **«Полный список»** и в нужный тематический раздел выше.
3. Если есть пример кода — положи в `verse/<категория>/` и добавь в «Карту примеров».
4. Добавь ссылку в корневой [`README.md`](../README.md).
