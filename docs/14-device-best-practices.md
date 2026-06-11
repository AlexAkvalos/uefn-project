# 14. Как делать Verse-устройства правильно

Архитектура чистых, логичных, переиспользуемых и удобных Verse-устройств. Собрано из официальной доки Epic,
«Verse Codex» и практики топ-разработчиков (2026).

Рабочий пример из этих принципов:
[`../verse/devices/pickup_device.verse`](../verse/devices/pickup_device.verse) +
[`../verse/devices/score_manager_device.verse`](../verse/devices/score_manager_device.verse).

---

## 0. Главная идея: `creative_device` — тонкая «обёртка», не свалка логики

`creative_device` — это **адаптер к редактору** (хранит editable-ссылки, запускает `OnBegin`, связывает всё).
Тренд 2026: **логика и состояние живут в обычных `class`, а не в устройстве.**

```verse
# Тонкое устройство: только проводка + editable-ссылки
my_game_device := class(creative_device):
    @editable
    SpawnPads : []player_spawner_device = array{}

    OnBegin<override>()<suspends>:void=
        Manager := round_manager{Spawners := SpawnPads}   # отдаём логику обычному классу
        Manager.Run()

# Вся настоящая логика — здесь, без зависимости от lifecycle устройства
round_manager := class:
    Spawners : []player_spawner_device
    Run()<suspends>:void = {}
```

Плюсы: логика переиспользуема между устройствами и проектами, не тащит за собой жизненный цикл актора.

---

## 1. @editable-свойства — выноси опции грамотно

`@editable` показывает поле в панели **Details**. Меняет **только этот экземпляр** устройства (это фича).

- **Всегда задавай дефолты** — устройство должно работать сразу после установки.
- **ToolTip** — подпись опции (само-документирование для дизайнера):
  ```verse
  @editable{ ToolTip := "Урон за тик, пока игрок в зоне." }
  DamagePerTick : float = 10.0
  ```
- **enum** для фиксированного выбора → выпадающий список вместо «магического» числа:
  ```verse
  zone_mode := enum{ Damage, Heal, Slow }
  @editable
  Mode : zone_mode = zone_mode.Damage
  ```
- **Массив**, а не отдельное поле на каждый объект — `[]trigger_device`, не пять полей.
- **Ссылка на устройство vs тег:**
  - editable-ссылка — явная проводка в редакторе, строгая типизация. Для небольшого фиксированного набора.
  - теги (`GetCreativeObjectsWithTag`) — для большого/динамического набора; слабее типизация, нужен рантайм-поиск.
  - Правило: **малое/фиксированное → ссылки; массовое/динамическое → теги.**

> ⚠️ Группировка `Category`/`Categories` на **устройствах** в части версий 2026 работает нестабильно
> (надёжно — в NPC Behavior классах). `ToolTip` работает. Проверяй в своей версии UEFN.

---

## 2. Событийная модель (publisher/subscriber)

Свои события → другие части кода реагируют без жёсткой связи. Событие может нести payload:

```verse
RoundStarted<public> : event() = event(){}
PlayerScored<public> : event(agent) = event(agent){}

StartRound():void= RoundStarted.Signal()
AwardPoint(P : agent):void= PlayerScored.Signal(P)
```

Два способа слушать:
```verse
# Subscribe — привязать обработчик, вернёт отменяемую подписку
Sub := PlayerScored.Subscribe(OnScored)
Sub.Cancel()   # отписаться

# Await — приостановиться до следующего сигнала (в <suspends>-контексте)
loop:
    RoundStarted.Await()
    StartNewRound()
```

Подписка на **встроенные** события устройств (стандартный паттерн — не поллить, а слушать):
```verse
for (Trigger : TriggersToWatch):
    Trigger.TriggeredEvent.Subscribe(OnTriggered)
```

**Принцип:** publisher зовёт `Signal()` и ничего не знает о подписчиках. Это позволяет менять/расширять устройства без перепроводки.

> ⚠️ У «голого» `event()` поддержка `Subscribe` исторически ограничена (надёжнее `Await`).
> Для полноценного pub/sub с несколькими обработчиками многие делают свой класс-диспетчер
> (массив функций-обработчиков + вызвать всех на `Signal`). Сверься со своей версией.

---

## 3. Инкапсуляция и модульность

- **Одно устройство — одна задача.** «Бог-устройство» на 1500 строк — классический анти-паттерн.
- **Переиспользуемая логика — в обычных `class`/`module`**, не в подклассах `creative_device`.
- **`OnBegin` оркеструет, а не реализует** — выноси детали в helper-функции.
- **Паттерн «менеджер»:** один координатор хранит ссылки на воркеров (через массив), слушает их события,
  владеет общим состоянием. Воркеры — «тупые» и переиспользуемые, правила — у менеджера.

---

## 4. Именование и стиль (Verse Codex)

| Что | Стиль | Пример |
| --- | --- | --- |
| Типы (class/struct/enum, **имена устройств**) | `snake_case` | `round_manager`, `pickup_device` |
| Функции / методы | `PascalCase` | `StartRound()`, `TryGetCharacter()` |
| **Переменные / поля / параметры** | `PascalCase` | `DamagePerTick`, `MaybeAgent` |
| Failable-геттеры | префикс `Try` + `[]`/`?` | `GetFortCharacter[]` |
| Булевы-запросы | `Is`/`Has` | `IsActive[]` |
| Файлы | `snake_case.verse` (= имя главного типа) | `round_manager.verse` |

⚠️ Особенность Verse: **переменные в PascalCase**, не camelCase. `snake_case` — только для типов.
Комментарии — `#`, блочные — `<# … #>`.

---

## 5. Надёжность (defensive coding)

Контексты провала Verse заставляют обрабатывать «может не быть» на этапе компиляции — используй это.

```verse
# Failable-выражения — в [] и внутри контекста провала (if/for/while)
if (FortChar := Player.GetFortCharacter[]):
    FortChar.Damage(10.0)

# Option ?T — «возможно есть»
var LastHit : ?player = false
if (Hitter := LastHit?): Print("есть бивший")

# Гард для editable-ссылок (дизайнер мог забыть привязать)
if (Spawner := SpawnPads[0]):
    Spawner.Enable()
else:
    Print("ВНИМАНИЕ: spawn pad не назначен")
```

Проверяй `IsActive[]` перед действиями над персонажами (игроки выходят, персонажи умирают).
Никогда не считай, что индекс/каст/тег-поиск точно успешны — оборачивай всё.

---

## 6. Состояние

- **`const` по умолчанию, `var` — только когда правда меняется.** Иммутабельность вперёд.
- Состояние — **в классах/структурах**, а не россыпью `var` по устройству.
- **Per-player состояние — в map по ключу `agent`/`player`:**
  ```verse
  var PlayerScores : [player]int = map{}
  ```
- **`weak_map`** — для player→state с автоочисткой/персистентностью (нельзя итерировать, доступ по ключу).
- **Чисти** записи по игроку на событии выхода, иначе утечки.

---

## 7. Жизненный цикл

- **`OnBegin<override>()<suspends>:void`** — точка входа (async: можно `Await`/`Sleep`/`spawn`/`loop`).
- **`OnEndGame`** — очистка в конце матча.
- ⚠️ **Гоча №1:** editable-ссылки могут быть **не готовы** в самый момент `OnBegin`.
  Лечится пропуском кадра:
  ```verse
  OnBegin<override>()<suspends>:void=
      Sleep(0.0)            # дать другим устройствам доинициализироваться
      # дальше ссылки безопасны
  ```
- **Порядок инициализации устройств не гарантирован.** Если B зависит от A —
  пусть A шлёт «ready»-событие, а B его `Await`, а не полагайся на порядок.

---

## 8. Что делает устройство удобным для дизайнера

- Хорошие **дефолты** — работает сразу.
- Понятные имена опций + **ToolTip**.
- **Минимум обязательной проводки** (теги/авто-поиск вместо ручной привязки кучи ссылок).
- Если ссылка обязательна и не привязана — **падай громко** (`Print`-предупреждение), а не молчи.
- **enum/диапазоны** — чтобы нельзя было ввести невалидное.

---

## 9. Анти-паттерны (избегай)

1. «Бог-устройство» со всей логикой и состоянием.
2. `creative_device` как обычный класс для логики.
3. Отдельное editable-поле на каждый объект вместо массива.
4. `OnBegin` трогает editable-ссылки на кадре 0 (нужен `Sleep(0.0)`).
5. Игнор контекстов провала / вытаскивание из option без `if`.
6. Жёсткая связь: устройства зовут методы друг друга вместо событий.
7. Поллинг в `loop`+`Sleep` там, где нужен `Await`/`Subscribe`.
8. Зависимость от порядка инициализации устройств.
9. Не чистить подписки (`Cancel()`) и записи per-player → утечки.
10. camelCase у переменных (в Verse — PascalCase).

---

## Разбор примера (pickup + score_manager)

- `pickup_device` — **single responsibility**: знает только про себя, публикует `Collected`. Переиспользуем.
- `score_manager_device` — **менеджер**: владеет правилами и счётом, слушает события предметов.
- **Связь через события** (decoupling): предмет не знает про счёт, менеджер не лезет внутрь предмета.
- **Гарды**: `?agent` разворачивается через `if`, пустой массив предметов → громкое предупреждение.
- **Дефолты + ToolTip** → работают из коробки и понятны дизайнеру.
- **`Sleep(0.0)`** → нет ловушки порядка инициализации.

---

## Источники
- Editable Properties: https://dev.epicgames.com/documentation/en-us/fortnite/editable-properties-in-verse
- Coding Device Interactions: https://dev.epicgames.com/documentation/en-us/fortnite/coding-device-interactions-in-verse
- Specifiers and Attributes: https://dev.epicgames.com/documentation/en-us/fortnite/specifiers-and-attributes-in-verse
- Verse Codex (naming/structure/clarity): https://forums.unrealengine.com/t/verse-codex-naming-conventions-program-structure-code-clarity/838073
- «Always add a frame of delay to OnBegin»: https://forums.unrealengine.com/t/important-verse-tip-always-add-frame-of-delay-to-your-onbegin-method/858419
- «Stop heavy use of creative_device» (E. Kawano): https://medium.com/@ekawano114/uefn-try-to-stop-heavy-use-of-creative-device-class-in-verse-896bc5b12ed8
- Map in Verse: https://dev.epicgames.com/documentation/en-us/fortnite/map-in-verse
