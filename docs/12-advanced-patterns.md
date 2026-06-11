# 12. Продвинутые паттерны Verse (от профи)

Приёмы, которыми пользуются топовые UEFN-разработчики. Собрано из официальной доки, блогов и постов в X (2026).

---

## 🔁 Конкурентность (concurrency)

Verse — про асинхронность. Главные конструкции:

| Конструкция | Назначение |
| --- | --- |
| `loop` | бесконечный цикл (часто игровой) |
| `Sleep(t)` | приостановка на `t` секунд (только в `<suspends>`) |
| `race { A; B }` | запустить параллельно, **первый завершившийся отменяет остальных** |
| `sync { A; B }` | запустить параллельно и **дождаться всех** |
| `branch { A }` | отделить async-ветку, не дожидаясь её |
| `spawn { A }` | «аварийный люк» — по возможности предпочитай `branch` |

Совет профи: используй `race`, чтобы чисто отменять сложную async-логику (например, «таймер ИЛИ нажатие кнопки»).

> https://dev.epicgames.com/documentation/en-us/fortnite/concurrency-in-verse ·
> https://dev.epicgames.com/documentation/en-us/fortnite/sync-in-verse

---

## 💾 Персистентность (сохранения)

- Глобальный **`weak_map`**, ключом — тип `player`:
  ```verse
  var PlayerScores : weak_map(player, int) = map{}
  ```
  Доступ по ключу (итерация запрещена).
- **Сохраняй на значимых событиях** (level-up, разблокировка, конец сессии), а не на каждое изменение — иначе лаги.
- **Версионируй структуры**: храни поле `Version`, при загрузке мигрируй старые данные в текущий формат.
  Это спасает от ошибки `Unable to update map already published` при изменении формы сохранённых данных.
- Используй **конструктор** Verse для обновляемых persisted-структур.

> https://dev.epicgames.com/documentation/en-us/fortnite/verse-persistence-best-practices ·
> https://romeroblueprints.blogspot.com/2026/02/uefn-verse-constructor-and-persistence.html

---

## 🎯 Raycasting через Scene Graph (чистый Verse)

- `FindSweepHits()` возвращает попадания sweep'а → достаёшь **hit entity** и делаешь с ним что угодно.
- ⚠️ Гоча: на целевой геометрии должна быть включена **«Generate Hit»**, иначе луч ничего не находит.
- Готовая open-source реализация: **tuurGevers/uefn_raycasting**.

> https://github.com/tuurGevers/uefn_raycasting/blob/master/Main.verse ·
> https://x.com/hoskij/status/1864950878756876616

---

## 🖥️ Реактивный UI (data binding)

- Привязывай текст/иконки к **`subscribable`**-переменным → при изменении значения виджет
  обновляется сам (`SetText()` и запись свойств).
- UI в Verse **полностью кодовый** — визуального редактора нет; иерархия виджетов строится в коде,
  позиционирование через anchors/offsets.
- Для сложного UI — **MVVM** (Model-View-ViewModel) биндинги.

> https://dev.epicgames.com/documentation/en-us/fortnite/creating-in-game-ui-in-verse ·
> https://uefncentral.com/blog/how-to-build-dynamic-ui-with-verse-data-binding-in

---

## 🐛 Производительность и стабильность (боль реальных карт)

- **Всегда проверяй `FortCharacter.IsActive[]`** перед использованием — иначе краш Verse-рантайма,
  если игрок не жив. (Урок от @kamyker, который чинил 20+ утечек памяти на карте с 51k CCU.)
- Не держи ссылки на «мёртвые» объекты — источник утечек.
- Профилируй регулярно (Spatial Profiler, Memory Snapshot из v41) — каждый новый ассет может всё уронить.

> https://x.com/kamyker/status/1788285314819043404

---

## 📦 Open-source библиотеки и сниппеты

| Репозиторий | Что внутри |
| --- | --- |
| [awesome-verse](https://github.com/spilth/awesome-verse) | курируемый хаб ресурсов (старт отсюда) |
| [UnrealVerseGuru/VerseProgrammingLanguage](https://github.com/UnrealVerseGuru/VerseProgrammingLanguage) | референс языка + сниппеты |
| [MadsMGrin/Verse](https://github.com/MadsMGrin/Verse) | большая коллекция готовых скриптов |
| [Bexarclaw/UEFN-Verse-Snippets](https://github.com/Bexarclaw/UEFN-Verse-Snippets) | сниппеты по типам механик |
| [tuurGevers/uefn_raycasting](https://github.com/tuurGevers/uefn_raycasting) | рейкастинг на Scene Graph |
| [tuurGevers/UEFN_NPC_utils](https://github.com/tuurGevers/UEFN_NPC_utils) | утилиты для NPC/игроков |
| [UEFN TOOLBELT](https://forums.unrealengine.com/t/open-source-project-uefn-toolbelt-287-python-tools-for-world-building-verse-automation/2709005) | 287+ Python-тулзов (скаттеринг, codegen Verse) |

VS Code: расширение **Verse Auto Imports** — автодобавление недостающих `using`.

---

## Кого читать (углублённо)

- **Romero Blueprints** — детальные письменные разборы Verse/Scene Graph (очень активен в 2026): https://romeroblueprints.blogspot.com/
- **@kamyker** — про-программист, перф и утечки памяти: https://x.com/kamyker
- **Mango** — узкие end-to-end туториалы + исходники: https://mangouefn.dev/
- **Cleverlike (UEFN Creator School)**: https://uefn.cleverlike.com/course/uefn-verse
