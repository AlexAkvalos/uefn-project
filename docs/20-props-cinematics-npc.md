# 20. Пропы, синематики и NPC с ними

Работа с пропами (`creative_prop`), кинематикой (`cinematic_sequence_device`) и тем, как NPC с ними взаимодействуют.
Примеры: [`../verse/devices/ping_pong_mover.verse`](../verse/devices/ping_pong_mover.verse),
[`../verse/devices/cinematic_trigger.verse`](../verse/devices/cinematic_trigger.verse).

---

## A. Пропы (`creative_prop`)

### Спавн и удаление
`SpawnProp` — свободная функция (не метод), создаёт проп в рантайме:
```verse
SpawnProp(Asset:creative_prop_asset, Position:vector3, Rotation:rotation)<transacts>
    : (?creative_prop, spawn_prop_result)
```
Возвращает кортеж: `?creative_prop` (false при неудаче) + результат. Есть async-вариант `SpawnPropAsync(...)<suspends>`
(ждёт стриминга ассета — предпочтительнее, если ассет может быть не загружен).

```verse
Result := SpawnProp(PropAsset, SpawnPos, IdentityRotation())
if (NewProp := Result(0)?):
    set MaybeProp = option{ NewProp }
```

**Жизненный цикл/видимость `creative_prop`:**
- `Dispose()` — уничтожить и убрать с острова;
- `IsValid[]` / `IsDisposed[]` — failable-проверки;
- `Hide()` / `Show()` — скрыть/показать (выключает/включает коллизию) — каноничная «исчезающая платформа»;
- `SetMesh(...)` / `SetMaterial(...)` — менять меш/материал в рантайме.

### Движение/анимация
```verse
GetTransform():transform
MoveTo(Position:vector3, Rotation:rotation, Time:float)<suspends>:move_to_result
MoveTo(Transform:transform, Time:float)<suspends>:move_to_result        # overload
TeleportTo(Position:vector3, Rotation:rotation)<transacts><decides>:void
```
- ⚠️ **`RotateTo` НЕТ** — поворачивай через `MoveTo` с новой `rotation`.
- `MoveTo` асинхронна и возвращается по завершении — это «двигатель» цикла (без отдельного MoveComplete-события).

**Паттерн Fall Guys (вращение/туда-обратно):** `spawn{}` на каждый проп + `loop`, читающий трансформ заново:
```verse
RotateProp(Prop : creative_prop)<suspends>:void=
    loop:
        T := Prop.GetTransform()
        NewRot := T.Rotation.ApplyYaw(180.0)
        Prop.MoveTo(T.Translation, NewRot, TimeRot180)

OnBegin<override>()<suspends>:void=
    for (P : PropsToRotate):
        spawn{ RotateProp(P) }
```
Пример «туда-обратно» — [`ping_pong_mover.verse`](../verse/devices/ping_pong_mover.verse).
Для плавности с easing/loop есть слой animation-controller (`MoveToEase`, режимы `Loop`/`PingPong`) — но это
паттерн из туториала (extension-методы), не гарантированный встроенный API. `MoveTo` — точно встроенный.

### Ссылки и теги
```verse
@editable MyProp  : creative_prop = creative_prop{}
@editable MyProps : []creative_prop = array{}
```
Поиск по тегу в рантайме:
```verse
my_platform_tag := class(tag){}
for (Obj : GetCreativeObjectsWithTag(my_platform_tag{})):
    if (Prop := creative_prop[Obj]):     # каст creative_object -> creative_prop
        spawn{ RotateProp(Prop) }
```

### Физика пропов (v39)
В редакторе — компонент **FortPhysics** (инструмент Add Physics, ставит Simulate Physics = True). Verse:
```verse
SetDynamic(IsDynamic:logic):void       # нужно dynamic, чтобы силы применялись
GetMass():float
GetLinearVelocity():vector3 / SetLinearVelocity(...)
ApplyForce(Force:vector3):void          # Ньютоны
ApplyLinearImpulse(Impulse:vector3):void
ApplyTorque / ApplyAngularImpulse(...)
```
```verse
LaunchProp(Prop:creative_prop):void=
    Prop.SetDynamic(true)
    Prop.ApplyLinearImpulse(vector3{X:=0.0, Y:=0.0, Z:=5000.0})
```
⚠️ Чистого события коллизии на проп в Verse пока нет (область развивается).

---

## B. Синематики

### `cinematic_sequence_device` — управление из Verse
У каждого метода есть вариант «для всех» и `(Agent:agent)` (для одного игрока):
```verse
Play() / Play(Agent)        Stop() / Stop(Agent)
PlayReverse(...)            Pause(...) / TogglePause(...)
GoToEndAndStop(...)
GetPlaybackTime():float / SetPlaybackTime(Time:float):void
GetPlayRate():float / SetPlayRate(Rate:float):void
StoppedEvent : listenable(payload)      # сигналит при остановке
```

### Sequencer (катсцены)
Cinematic Sequence device проигрывает **Level Sequence** из Sequencer: треки скелетных мешей (через Animated Mesh device/FBX),
Camera Cut треки, пропы. **Gameplay Events** на секвенции вызывают привязанные девайсы в нужный момент.

### Скрытие HUD + камера
```verse
HUDController := GetPlayspace().GetHUDController()
HUDController.HideElements(array{ creative_hud_identifier_all{} })
# вернуть: ResetElementVisibility(...) или ShowElements(...)
```
⚠️ `GetHUDController().HideElements/ShowElements` бьёт по **всем игрокам** (баг). Для per-player — `(PlayerUI:player_ui).HideHUDElements`.
Переход камеры в катсцене — через Cinematic Camera / Camera-девайсы или Camera Cut трек секвенции.

Пример «триггер → кинематика + скрыть HUD» — [`cinematic_trigger.verse`](../verse/devices/cinematic_trigger.verse).

---

## C. NPC с пропами и синематиками

### NPC + пропы
NPC реализуют интерфейс `fort_character`. Готового `NPC.EquipProp` **нет**. Варианты «нести/использовать проп»:
- прикрепить `creative_prop` и обновлять его трансформ за NPC каждый тик (attach-and-follow);
- задать оружие/предмет в **NPC Character Definition** (экипировка — настройка определения, не creative_prop).
Навигация/поведение — из AI-модуля (см. [18-ai-npc-scene-graph.md](18-ai-npc-scene-graph.md)).

### NPC в катсценах
- Перетащи **NPC Spawner device** в трек-лист Level Sequence из Outliner;
- или пусть секвенция **спавнит актёра из Character Definition** и **анимирует его в Sequencer** как любой скелетный меш;
- кастомные анимации проигрываются на NPC Spawner через события / в паре с Cinematic Sequence device.
- Диалоги — **Conversation device** (ветвящиеся), хорошо комбинируется с кинематикой.

### Официальные туториалы
- «Animating Prop Movement in Verse» (Fall Guys, 6 частей) — источник паттернов `MoveTo`/`spawn{}`/rotating.
- «Animation and Cinematics in UEFN», «Cinematic Sequence Device» — катсцены, NPC в секвенции, gameplay events.

---

## Источники
- creative_prop: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/creative_prop
- SpawnProp: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/spawnprop
- Animating Prop Movement (Fall Guys): https://dev.epicgames.com/documentation/en-us/fortnite/animating-prop-movement-in-verse
- cinematic_sequence_device: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/cinematic_sequence_device
- Animation and Cinematics: https://dev.epicgames.com/documentation/en-us/fortnite/animation-and-cinematics-in-unreal-editor-for-fortnite
- Getting Started with Physics: https://dev.epicgames.com/documentation/en-us/fortnite/getting-started-with-physics
- HUD hide affects all players (баг): https://forums.unrealengine.com/t/normal-verse-hidehudelements-and-showhudelements-effect-all-players-not-the-targetted-player/790007

> ⚠️ Помечено: `MoveToEase`/animation-controller — паттерн из туториала, не гарантированный встроенный API;
> per-prop коллизии физики и per-player HUD-hide — развивающиеся/с оговорками. Сверяй в Verse API браузере.
