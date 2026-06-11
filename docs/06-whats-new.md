# 06. Что нового (сезоны 38–39)

Краткая выжимка свежих релиз-ноутов Fortnite Ecosystem / UEFN. Полные тексты — на сайте Epic.

---

## v39.30 (последняя в изученной документации)

- **Fortnite Tools Mode**: новые инструменты оптимизации — **Optimize Textures**, **Optimize Static Mesh**, **Add Physics**.
- **User Interfaces** шаблон обновлён: кастомные Verse-кнопки, UI на данных Verse, кастомные HUD транспорта.
- **Ch7 BR HUD** включается опцией острова **Use Latest HUD**.
- Новые debug-команды: **Toggle FN HUD Visibility**, **Change Time Of Day**.
- `fort_item_pickup_component` **устарел** → замена на подкласс `interactable_component`.
- Новые префабы/галереи: **Brutal Bastion**.

## v39.00 (крупный релиз)

- **In-Island Transactions**: тестирование ограничений и флоу покупок; флаг `ConsequentialToGameplay`; публикация с 9 января 2026.
- **Physics Verse API**: скорость/масса/импульсы/силы для `fort_character` и `creative_prop`.
- **Chaos Visual Debugger (CVD)** включён для UEFN.
- **Scene Graph AI**: компоненты `npc_actions_component`, `guard_actions_component`, `npc_awareness_component`, `guard_awareness_component`.
- **Mobile Preview** + обновления **Input Trigger device** (тач-управление, виртуальный джойстик).
- **Spatial Profiler** улучшен (цветовые пороги метрик).
- **Pacific Break** (Глава 7): 30+ галерей, новое оружие, **Wingsuit**, обновлённый **Down But Not Out**.
- **Epic's Picks**: обязательная аттрибуция ассетов.
- Verse API для устройства **Reboot Van**.

## v38.x

- Развитие Scene Graph: `agent` стал подклассом `entity`; перегрузки agent/entity больше не компилируются (нужно использовать единый `entity`).
- Развитие кастомного UI и MVVM.

---

## Что это значит для разработки

1. **Scene Graph — будущее.** Новые системы (физика, AI, кастомные предметы) строятся на компонентах.
   Стоит осваивать entity-component подход.
2. **Монетизация стала реальной** — In-Island Transactions вышли из эксперимента.
3. **Физика на Verse** открывает новые механики (импульсы, силы напрямую из кода).
4. **Мобилки — приоритет.** Mobile Preview и тач-ввод — Epic явно толкает мобильную аудиторию.
5. **Оптимизация важна** — новые инструменты Fortnite Tools и лимиты памяти.

---

## Где смотреть свежие новости

- Релиз-ноуты: https://dev.epicgames.com/documentation/en-us/fortnite/fortnite-ecosystem-updates-and-release-notes
- Что нового в UEFN: https://dev.epicgames.com/documentation/en-us/fortnite/whats-new-in-unreal-editor-for-fortnite
- Форумы разработчиков: https://forums.unrealengine.com/c/fortnite-creative/
- Creator Portal: https://create.fortnite.com/
