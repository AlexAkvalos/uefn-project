# 18. AI / NPC через Scene Graph

Создание и управление NPC в UEFN. Современный путь — **Scene Graph AI-компоненты** (v39.00, июнь 2026),
которые заменили старые интерфейсы. Рабочий пример: [`../verse/ai/reactive_guard_behavior.verse`](../verse/ai/reactive_guard_behavior.verse).

---

## 1. Три пути для NPC (стакаются на одном `fort_character`)

| Путь | Что это | Когда |
| --- | --- | --- |
| **Устройства** | `npc_spawner_device`, Guard/Creature/Wildlife Spawner | быстро, без/мало кода |
| **Verse-мозг** | класс `npc_behavior` (своя логика, `OnBegin` на каждого NPC) | кастом: торговцы, медики, боссы, патрули |
| **Scene Graph компоненты (v39)** | `npc_actions_component`, `guard_actions_component`, `npc_awareness_component`, `guard_awareness_component` | современный, реактивный, масштабируемый AI |

Обычно: устройство **спавнит** NPC, ты пишешь `npc_behavior` (мозг), а внутри достаёшь **компоненты** сущности
для движения/атаки/восприятия.

**Замена интерфейсов (v39):**
- `npc_actions_component` заменяет `navigable` + `focusable`.
- `guard_actions_component` заменяет `leashable`.
Старый путь (туториал «NPC Medic») ещё работает, но для нового кода — компоненты.

---

## 2. Доступ к компонентам

```verse
using { /Fortnite.com/AI }
using { /Verse.org/SceneGraph }

# Внутри npc_behavior:
if:
    Entity    := GetEntity[]                                # failable
    Actions   := Entity.GetComponent[npc_actions_component] # failable
    Awareness := Entity.GetComponent[guard_awareness_component]
then:
    # пользуемся Actions / Awareness
```

`GetEntity[]` и `GetComponent[T]` — **failable** (квадратные скобки), всегда в `if`.

---

## 3. Компоненты — состав

### `npc_actions_component` (движение + фокус)
- `MovementSpeedMultiplier : ?float` (0.5–2);
- `NavigateTo(Target, MovementType, ReachRadius, AllowPartialPath)<suspends>` → `navigation_result`;
- `StopNavigation()`, `GetCurrentDestination()`;
- `Focus(Location|Entity)` — смотреть на точку/сущность; `Idle(Duration)`.

### `guard_actions_component` (бой + страж) — заменяет `leashable`
Всё из actions, плюс:
- **Бой:** `Attack()` (нужна обнаруженная цель), `MoveInRangeToAttack()`;
- **Стойки/движение:** `Jump()`, `Crouch()`, `StandUp()`, `Slide()`, `RoamAround()`;
- **Привязка (вместо leashable):** `Tether(Position|Entity, Radius)`, `Untether()`;
- **Поддержка:** `Revive(Target)`, `PlayRandomEmote()`.

### `npc_awareness_component` (восприятие)
- `DetectedTargets : ?[]npc_target_info`;
- события: `DetectTargetEvent`, `ForgetTargetEvent`, `SeeTargetEvent` (зрение), `HearTargetEvent` (слух), `TouchTargetEvent` (касание).

### `guard_awareness_component` (восприятие + угроза + препятствия + тревога)
Всё из awareness, плюс:
- `AlertLevel : ?guard_alert_level` + `AlertLevelChangeEvent`, `GetAlertLevel()`;
- `PrimaryThreat : ??npc_target_info` + `PrimaryThreatChangeEvent` — главная цель для боя;
- `DetectedObstacle`, `DetectObstacleEvent`, `ForgetObstacleEvent`.

### `npc_target_info` (что такое обнаруженная цель)
- `Target : entity`, `HasLineOfSight : ?logic`, `Attitude : ?team_attitude`,
  `LastKnownPosition : ?vector3`, `OnUpdateEvent`.

---

## 4. `npc_behavior` — мозг

```verse
my_behavior := class(npc_behavior):
    OnBegin<override>()<suspends>:void = {}   # NPC добавлен в симуляцию
    OnEnd<override>():void = {}               # NPC удалён
```
- `GetAgent[]` → `agent`; `GetEntity[]` → `entity` (шлюз к компонентам).
- Через `Agent.GetFortCharacter[]` → `fort_character` (классика: `GetHealth/SetHealth/GetTransform`).
- **Привязка:** файл по шаблону **NPC Behavior** → собрать Verse → в NPC Spawner поле **NPC Behavior** указать класс.

---

## 5. Навигация

```verse
NavTarget := MakeNavigationTarget(TargetPosition)   # vector3 ИЛИ agent/entity (следовать)
Result := Actions.NavigateTo(NavTarget, movement_type.Running, 150.0, true)
Actions.StopNavigation()
```
- `MakeNavigationTarget(...)` — из позиции или из сущности/агента (следование).
- `movement_type`: `Walking` / `Running` (⚠️ баг: `Running` иногда играет walk-скорость/анимацию).
- `NavigateTo` асинхронна (`<suspends>`), возвращает результат — ветви логику по достижению.
- Патруль = `loop` по массиву точек; подход к бою = `MoveInRangeToAttack()` → `Attack()`.

---

## 6. Восприятие

```verse
Awareness.SeeTargetEvent.Subscribe(OnSaw)
Awareness.ForgetTargetEvent.Subscribe(OnLost)
Awareness.PrimaryThreatChangeEvent.Subscribe(OnThreat)
Awareness.AlertLevelChangeEvent.Subscribe(OnAlert)
```
- Зрение/слух/касание срабатывают только если сенс активен.
- `HasLineOfSight` — видна ли цель сейчас; `LastKnownPosition` — куда идти искать после потери LOS.
- `PrimaryThreat` — самая релевантная цель, обычно её и атакуют.

---

## 7. Спавн и управление — `npc_spawner_device`

```verse
@editable Spawner : npc_spawner_device = npc_spawner_device{}
OnBegin<override>()<suspends>:void=
    Spawner.SpawnedEvent.Subscribe(OnSpawned)
    Spawner.EliminatedEvent.Subscribe(OnEliminated)
    Spawner.Spawn()
    Spawner.SpawnAt(SomePosition)   # v39+: спавн в точке (меньше устройств)
```
- `Spawn()`, **`SpawnAt(Position, ?Rotation)` (v39)**, `DespawnAll(?Instigator)`, `Enable/Disable/Reset`, `GetAgents()`.
- `SpawnedEvent` (отдаёт `agent`), `EliminatedEvent` (`Source` — кто убил).
- **v39:** Wildlife/Guard Spawner отражают `Damage`/`Speed`/`Health` в Verse — можно менять в рантайме.

---

## 8. Внешность, диалоги, LLM-NPC

- **Внешний вид:** `CharacterDefinition` (меш/аутфит/поведение по умолчанию); NPC Spawner поддерживает кастомные анимации.
- **Скриптовые диалоги:** связка **NPC + Conversation device** (ветвящиеся диалоги).
- **AI-Powered Conversations (v40.20, эксперимент):** NPC с живой неподготовленной речью.
  Стек: **Google Gemini 3.1 Flash Lite** (аудио→текст) + **ElevenLabs** (текст→голос).
  Персона задаётся промптами (характер, база знаний, поведение — «от 20 строк»).
  ⚠️ **Эксперимент — острова с этим нельзя публиковать** до выхода в Beta.

---

## 9. Лимиты, гочи, best practices

- `GetEntity[]`/`GetComponent[]` — **failable**, всегда в `if`; забыл собрать Verse → молча падает.
- Кастомным компонентам нужен `class<final_super>(component)` и `(super:)OnBeginSimulation()` первым.
- ⚠️ `movement_type.Running` иногда даёт walk-скорость — проверяй в сессии.
- ⚠️ Навигация — самая хрупкая по версиям область (бывали поломки `NavigateTo` после раунда 1). Ретести после апдейтов.
- `Attack()` **требует обнаруженной цели** (читает awareness) — связывай оба компонента.
- Кастомные поведения NPC исторически ломались на апдейтах UEFN — пинуй версию, ретести.
- Не мешай старые интерфейсы и новые компоненты на одном NPC — для нового кода выбирай компоненты.

---

## Разбор примера (`reactive_guard_behavior.verse`)

- `OnBegin` достаёт `guard_actions_component` + `guard_awareness_component`, подписывается на зрение/угрозу/потерю цели, запускает патруль `RoamAround()`.
- При обнаружении — `FindNearestTarget` выбирает ближайшую цель; `EngageTarget` фокусируется, идёт `NavigateTo`, `MoveInRangeToAttack`, `Attack`.
- При потере — `StopNavigation` + назад к патрулю.

---

## Источники
- npc_behavior: https://dev.epicgames.com/documentation/en-us/uefn/verse-api/fortnitedotcom/ai/npc_behavior
- npc_actions_component: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/ai/npc_actions_component
- guard_actions_component: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/ai/guard_actions_component
- npc_awareness_component: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/ai/npc_awareness_component
- guard_awareness_component: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/ai/guard_awareness_component
- npc_spawner_device: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/npc_spawner_device
- Understanding NPC Behavior: https://dev.epicgames.com/documentation/en-us/fortnite/understanding-npc-behavior-in-unreal-editor-for-fortnite
- AI-Powered Conversations: https://www.fortnite.com/news/bring-npcs-to-life-with-ai-powered-conversations
- v39.00 release notes: https://dev.epicgames.com/documentation/fortnite/39-00-fortnite-ecosystem-updates-and-release-notes

> ⚠️ Точные пути модулей AI-компонентов, форма `payload` и полный список `movement_type`
> зависят от версии — сверяй во встроенном Verse API браузере своей сборки.
