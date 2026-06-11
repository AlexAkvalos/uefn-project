# 15. Работа с данными и сохранения (persistence)

Всё про данные в Verse: типы, коллекции, **персистентность** (сохранения между сессиями), статистика, лидерборды, аналитика.
Рабочий пример: [`../verse/persistence/player_progress.verse`](../verse/persistence/player_progress.verse).

---

## 1. Типы данных

```verse
N    : int    = 13          # целое (big-integer, без лимита 32/64 бит)
F    : float  = 2.718       # 64-битный float
Flag : logic  = true        # true/false (это ЗНАЧЕНИЕ, не контекст провала)
Name : string = "admin"     # строка = []char (работают операции массива)
Ch   : char   = 'A'
```

**Касты явные**, сужающие — **failable** (в контексте провала):
```verse
MyFloat : float = ToFloat(MyInt)     # int -> float (расширение, всегда ок)
if (I := Int[MyFloat]) {}             # float -> int, failable (квадратные скобки)
Down := Floor(MyFloat)                # -> int (вниз);  Ceil/Round — тоже -> int
S := "{MyInt}"                        # в строку — интерполяция (самый надёжный способ)
```

**Кортежи** (фикс. размер, доступ по индексу): `Info(0)`, `Info(1)`.
**Enum** — для фиксированного набора (и они **сохраняемые**).
**struct vs class:** struct — значение (копируется, без методов/наследования); class — ссылка (методы, наследование). Маленький набор данных → struct; поведение/идентичность/то, что будешь сохранять и развивать → class.

---

## 2. Коллекции

| Тип | Создание | Доступ | Особенности |
| --- | --- | --- | --- |
| `array []T` | `array{1,2,3}` | `Arr[0]` (failable) | `.Length`, добавление через `+`, срез `Slice[a,b]` |
| `map [K]V` | `map{"k"=>1}` | `M[Key]` (failable) | `set M[K]=V`, `.Keys`, `.Values`, итерация `for (K->V : M)` |
| `option ?T` | `option{42}` / `false` | `Opt?` (failable) | «возможно есть значение» |
| `weak_map(K,V)` | `map{}` | `M[K]` (failable) | **нельзя итерировать**; контейнер персистентности |

```verse
for (Item : Items) {}                 # перебор
for (I -> Item : Items) {}            # с индексом
for (Item : Items, Item > 0) {}       # с фильтром
```

Доступ к элементам всегда **failable** — оборачивай в `if`. Это и спасает Verse от рантайм-крашей.

---

## 3. Персистентность (сохранения) — главное

### Механизм
Данные хранятся в **module-scoped** `var weak_map(player, T)`, где `T` — `<persistable>`-тип:

```verse
var SaveMap : weak_map(player, player_save) = map{}   # вне любого класса
```

### Что можно сохранять (savable)
Примитивы (`int/float/logic/char`), `string`, `enum`, `array`/`map`/`tuple`/`option` из сохраняемых,
часть value-типов (`vector3`, `color` — сверь версию). И:
- **struct `<persistable>`** — но **замораживается после публикации**;
- **class `<final><persistable>`** — **рекомендуемый** контейнер (можно расширять после публикации).

**Требования к persistable-классу:**
- спецификаторы `<final>` и `<persistable>`;
- **без суперкласса**, не `unique`/`parametric`;
- все поля сами сохраняемые;
- **нет `var`-полей** (только неизменяемые) — «меняешь» данные, создавая новый экземпляр и переприсваивая в weak_map.

### Чтение/запись
```verse
# Запись: копируем старое, переопределяем одно поле, переприсваиваем
if (Current := SaveMap[Player]):
    set SaveMap[Player] = player_save:
        V2 := option{ NewData }
# Чтение
if (Data := SaveMap[Player]) {}
```

Явного «Save()» нет — Verse сохраняет автоматически (транзакционно, сбрасывает на бэкенд на
значимых границах: выход игрока, конец раунда/сессии). Данные доступны **только пока игрок в игре**.
Новый игрок записи не получает — **инициализируй сам**.

### Лимиты (сверь с актуальной докой)
- ~**256 КБ на игрока** на weak_map (превышение → сейв падает).
- Небольшой лимит на **число persistence-weak_map на остров** (часто ~4) — консолидируй в один класс.

### ⚠️ Версионирование — как избежать «Unable to update map already published»
После публикации Epic проверяет обратную совместимость. Старые сохранения должны грузиться.

| Изменение после публикации | Можно? |
| --- | --- |
| Добавить **новое поле с дефолтом** в `<persistable>` **класс** | ✅ да |
| Сменить **тип** поля | ❌ нет |
| Удалить опубликованное поле | ❌ нет |
| Изменить `<persistable>` **struct** | ❌ нет (заморожен) |
| **Переместить файл** с persistence-map | ❌ нет |
| Откатить остров в Creator Portal | ⚠️ сбрасывает данные ВСЕХ игроков |

**Надёжный паттерн — обёртка с option на каждую версию:**
```verse
player_save := class<final><persistable>:
    V1 : ?progress_v1 = false
    V2 : ?progress_v2 = false
    # позже добавишь V3 : ?progress_v3 = false  (новое поле + дефолт = легально)
```
На загрузке берёшь самую свежую заполненную версию и мигрируешь старые вперёд.
Старые классы **никогда не редактируешь** — добавляешь новый класс-версию. См. рабочий пример.

### Best practices
- **Класс (не struct)** как тип weak_map — чтобы расширять потом.
- **Сохраняй на значимых событиях**, не каждый кадр.
- **Держи данные маленькими** (< 256 КБ); это не БД.
- **Дефолты у всех полей.**
- **Не двигай файл** и не переименовывай/не удаляй опубликованные поля.
- Тестируй сохранения в **playtest-сессии** (в edit-сессии персистентность сбрасывается).

---

## 4. Статистика и лидерборды

**A. Устройства (мало/без кода):** Stat Device (статистика), Leaderboard Device (рейтинг), Score Manager/Tracker.
**B. В Verse (полный контроль):** persistable-класс статов + weak_map (официальный сэмпл «Persistent Player Statistics»):
```verse
player_stats_table := class<final><persistable>:
    Version<public> : int = 0
    Score<public>   : int = 0
    Wins<public>    : int = 0
```
Лучший подход: **Verse владеет истиной** (персистентно), а Stat/Leaderboard-устройства её **отображают**.

---

## 5. Аналитика и метрики (для создателя)

**Creator Portal** (после публикации) даёт дашборды:
- **Active Playtime** (часы), **Retention** (Day N — возврат на N-й день), **Plays/уникальные игроки**.
- **Queue/wait times** (медиана + перцентили).
- **Playtime по размеру пати**, **Active Players by Party Size** (соц-метрики, дек. 2025).
- **Engagement Payout Estimates** (формула обновлена с 1 ноября 2025: Active Playtime + Playtime у Item Shop + V-Bucks Spend).
- Публичный **Fortnite Data API** — engagement/retention по всем островам (вкл. конкурентов).

**В игре:** **Analytics Device** — эмитит кастомные игровые события/статы из острова (Creative + UEFN).
Общего «послать произвольное событие из Verse» API нет — гоняй Analytics Device из Verse или веди свои счётчики в persistent-статах.

---

## 6. Моделирование данных в UEFN-игре

1. **Один persistent-класс на игрока** — XP/уровень/монеты/анлоки/статы в одном `<final><persistable>` за одним weak_map.
2. **Версионируй с первого дня** (`Version:int` или обёртка с option-версиями).
3. **Классы — для сохраняемых/развивающихся данных; struct — только для крошечных замороженных.**
4. **Иммутабельность + конструкторы** — обновление = «скопировать старое, переопределить поле, переприсвоить».
5. **Разделяй рантайм-состояние и сохраняемое** — в weak_map только долговременный прогресс.
6. **Дефолты везде.**
7. **Не реорганизуй опубликованные persistence-файлы/поля.**
8. Тестируй в **playtest**, не в edit-сессии.
9. **Гоняй устройства (stat/leaderboard/analytics) из Verse-источника истины.**

---

## Разбор примера (`player_progress.verse`)

- Версионированная схема `progress_v1` → `progress_v2` под обёрткой `player_save` с option-слотами.
- `LoadProgress` мигрирует v1→v2; `SaveProgress` пишет всегда под V2.
- Новый игрок инициализируется (`EnsurePlayer`); прогресс показывается на табло.
- Чтобы выпустить v3: добавляешь `progress_v3` + `V3:?progress_v3 = false`, расширяешь миграцию —
  старые классы не трогаешь, проверка совместимости проходит.

---

## Источники
- Using Persistable Data in Verse: https://dev.epicgames.com/documentation/fortnite/using-persistable-data-in-verse
- Verse Persistence Best Practices: https://dev.epicgames.com/documentation/en-us/fortnite/verse-persistence-best-practices
- Persistent Player Statistics: https://dev.epicgames.com/documentation/fortnite/persistent-player-statistics-in-unreal-editor-for-fortnite
- weak_map: https://dev.epicgames.com/documentation/en-us/uefn/verse-api/versedotorg/verse/weak_map
- Map / Array / Option: https://dev.epicgames.com/documentation/en-us/fortnite/map-in-verse · https://dev.epicgames.com/documentation/en-us/fortnite/array-in-verse · https://dev.epicgames.com/documentation/en-us/fortnite/option-in-verse
- Type Casting: https://dev.epicgames.com/documentation/en-us/fortnite/type-casting-and-conversion-in-verse
- Analytics Device: https://www.fortnite.com/news/get-play-stats-with-the-analytics-device-for-fortnite-creative-and-uefn
- Соц-метрики в Creator Portal (дек. 2025): https://forums.unrealengine.com/t/new-social-metrics-now-available-in-creator-portal-analytics/2686171
