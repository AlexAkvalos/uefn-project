# 23. Физика (Chaos, Verse Physics API)

Физика в UEFN на движке **Chaos**. Verse Physics API расширили в v37–v39 (импульсы/силы для пропов и персонажей).
Пример: [`../verse/devices/physics_launcher.verse`](../verse/devices/physics_launcher.verse).

---

## 1. Обзор

- Движок **Chaos**, F = ma. Beta (v37–v39), но **публиковать с физикой можно**.
- **`FortPhysics` component** — драйвер физики на объекте. Проп с ним + **Simulate Physics** = **dynamic** (физический); без — **static**.
  Свойства: Simulate Physics, **Override Mass** (кг), Enable Gravity, Start Awake (сон-оптимизация), Linear/Angular Damping,
  Impulse on Hit Multiplier, Rotation/Translation Constraints.
- **Включить Beta:** Project Settings → **Beta Access** → отметить **Physics**. ⚠️ Нельзя на brand-шаблонах; **нельзя отключить после публикации**.
- **Добавить физику:** Fortnite Tools → **Add Physics** (Ctrl+клик по пропам) / **Remove Physics** / **Select Physics**; или Details → `+ Add → Fort Physics` + Simulate Physics.

---

## 2. `creative_prop` — физический Verse API (v39)

`using { /Fortnite.com/Devices }`. Единицы: масса кг, скорость м/с (лин.) и рад/с (угл.), сила Н, момент Н·м, импульс Н·с.

```verse
GetDynamic():logic                              # физический ли проп
SetDynamic(Dynamic:logic):void                  # ОБЯЗАТЕЛЬНО true, иначе силы не применяются
GetMass():float                                 # кг
GetLinearVelocity():vector3 / SetLinearVelocity(Velocity:vector3):void
GetAngularVelocity():vector3 / SetAngularVelocity(Velocity:vector3):void
ApplyForce(Force:vector3):void                  # Ньютоны (постоянная сила)
ApplyTorque(Torque:vector3):void                # Н·м
ApplyLinearImpulse(Impulse:vector3):void        # Н·с (мгновенный толчок)
ApplyAngularImpulse(Impulse:vector3):void       # Н·м·с (закрутка)
```

⚠️ **Проп должен быть dynamic** (`SetDynamic(true)` / FortPhysics+Simulate), иначе все `Apply*`/`Set*Velocity` **молча ничего не делают**.

---

## 3. `fort_character` — физический Verse API (v39)

`using { /Fortnite.com/Characters }`. Толкать игроков физикой:
```verse
GetLinearVelocity():vector3 / SetLinearVelocity(Velocity:vector3):void
GetMass():float
ApplyForce(Force:vector3):void
ApplyLinearImpulse(Impulse:vector3):void
```
- У персонажей **нет угловых** (torque/angular — только у пропов).
- Все сеттеры **«ничего не делают, если физика выключена»**. Персонаж из агента — `Agent.GetFortCharacter[]`.
- ⚠️ Под физикой персонажа **отключены** mantling, slide, zipline, grind rail, DBNO.

---

## 4. Устройства физики
- **Совместимые:** Air Vent, Bouncer, D-Launcher, Hover Platform, Pinball Bumper/Flipper, Prop Mover, Crash Pad, Explosives, Carryable Spawner, Volume, Trigger и др.
- **Physics Constraint** — соединяет два физ-тела (петли, мосты, верёвки).
- **Гравитация:** per-prop (Enable Gravity) или зоной (**Mutator Zone** override).
- **Галереи** Sphere/Cube — готовые пропы под dynamic.
- **Volume** даёт событие **On Physics Enter** (без Verse).

---

## 5. Chaos Visual Debugger (CVD) — v39
Включён для UEFN: захват/инспекция/реплей физической сцены (геометрия, контакты коллизий, scene queries).
Открыть: **Tools → Debug → Chaos Visual Debugger**. Помогает понять, почему query вернул не то / неожиданная коллизия.

---

## 6. Коллизии в Verse
⚠️ **Чистого per-prop события коллизии в Verse пока НЕТ** (`creative_prop` без `OnHit`). Детектишь через **зоны/объёмы**:
```verse
# volume_device:
AgentEntersEvent : listenable(agent)        # игрок/NPC вошёл
AgentExitsEvent  : listenable(agent)
PropEnterEvent   : listenable(creative_prop) # физ-проп вошёл в объём
PropExitEvent    : listenable(creative_prop)
```
```verse
MyVolume.PropEnterEvent.Subscribe(OnPropEntered)
```
⚠️ Имена: `PropEnterEvent`/`PropExitEvent` (singular «Enter»), но `AgentEntersEvent` (plural «Enters») — легко опечататься.
Прочее: Mutator Zone, Trigger, Damage Volume, Prop Manipulator; либо поллинг позиций/скоростей.

---

## 7. Паттерны
- **Запуск пропа:** `SetDynamic(true)` → `ApplyLinearImpulse(Dir * Mag)` (импульс — для мгновенного; `ApplyForce` — для постоянного, вент/ветер).
- **Взрыв:** перебрать ближние dynamic-пропы, радиальное направление от центра, импульс ∝ массе / 1/дистанция.
- **Отброс игрока:** `Char.ApplyLinearImpulse(Dir * Force)` (масштабируй на `GetMass()`).
- **Закрутка:** `ApplyAngularImpulse`/`ApplyTorque` (пропы).
- **Паззл:** dynamic-куб + Physics Constraint + Volume `PropEnterEvent`.
- **Ragdoll:** через физику персонажа (помни про отключённые режимы движения).

---

## 8. Лимиты, перф, публикация
- ~**50 простых физ-форм** (боксы/сферы) — мягкий потолок; сложные коллизии дороже. `Start Awake = false` усыпляет покой.
- **Sequencer-анимированные** объекты **не взаимодействуют** с физикой.
- **Транспорт не поддерживается** с физикой.
- Физика — **только UEFN** (не Creative); Beta per-project; **необратимо после публикации**.
- v39 пофиксил баг `SetPhysicsLinearVelocity` — если тестил раньше, перетестируй.
- Силы на не-dynamic объекте **молча игнорируются** — причина №1 «ничего не происходит».

---

## Разбор примера (`physics_launcher.verse`)
- На триггере: `SetDynamic(true)` + `ApplyLinearImpulse` (запуск) + `ApplyAngularImpulse` (закрутка).
- В зоне: на входе игрока `Char.ApplyLinearImpulse(Dir * Force * Mass)` — отброс, масштабированный на массу.

---

## Источники
- Getting Started with Physics: https://dev.epicgames.com/documentation/en-us/fortnite/getting-started-with-physics
- creative_prop (Verse API): https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/creative_prop
- fort_character (Verse API): https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/characters/fort_character
- volume_device: https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/volume_device
- v39.00 release notes (CVD, physics API): https://dev.epicgames.com/documentation/fortnite/39-00-fortnite-ecosystem-updates-and-release-notes
- Physics Puzzle Dungeon: https://dev.epicgames.com/documentation/en-us/fortnite/make-a-physics-puzzle-dungeon-in-unreal-editor-for-fortnite

> ⚠️ Точный возвращаемый тип `GetDynamic` (`logic` vs `<decides>`) и спецификаторы части сеттеров
> рендерятся через JS — сверяй в Verse-автокомплите. Скорость в м/с vs см/с стоит проверить в CVD.
