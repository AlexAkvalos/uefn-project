# 22. VFX и Niagara

Визуальные эффекты в UEFN. Архитектура: **Niagara System (контент эффекта) → VFX Spawner device (плейсбл + Verse-хэндл) → Verse / Direct Event Binding.**
Пример: [`../verse/devices/explosion_on_event_device.verse`](../verse/devices/explosion_on_event_device.verse).

---

## 1. VFX в UEFN — три уровня

**a) Встроенные эффекты** (Content Browser → VFX): готовые **заблокированные** Niagara-ассеты
(Gas/Grenade Explosion, Impact, Torch, Spawn Effect, Wood/Stone Impact…). Перетаскиваешь в сцену или ссылаешься из устройства.

**b) VFX Spawner device** — устройство, которое играет Niagara-эффект. Ключевые опции:
- **Effect Type** — **Loop** (цикл) vs **Burst** (короткий выброс) → это переключатель one-shot/looping.
- **Visual Effect** (для loop) / **Burst Visual Effect** (для burst), **Sound Effect**.
- **Colorize VFX** + **Custom Color** — главный способ задать цвет (в редакторе, не из Verse).
- **Visible to Team/Class** (+ Invert) — per-team/class видимость (так делают «per-player» без Verse).
- **Spawn Rate**, **Enabled Time**, **Clear Particles on Disable**, **Enabled on Phase**.

**Direct Event Binding:** Enable/Disable/Restart When Receiving From; On Effect Enabled/Disabled Send Event To.

**c) Кастомные Niagara-системы** — свои ассеты в слоты Visual Effect/Burst Visual Effect.

---

## 2. Niagara

Niagara — система частиц UE5 (эмиттеры, модули, стадии). Авторишь в том же редакторе, что и в полном UE.
- Создание: Content Browser → **FX** → Niagara Emitter / System (System = набор Emitter'ов; Emitter = стек модулей).
- **Импорт в UEFN:** собери в standalone UE5 → ПКМ → **Asset Actions → Migrate** в Content проекта UEFN. На запуске — **Content Validation**.
- **Ограничения UEFN:** не все ноды/настройки доступны; запрещены Actor Component Interface ноды, Engine Content;
  **Color Curve не поддерживается** (воркэраунд — запечь в текстуру). Частые провалы валидации — missing Effect Type, LODBias.

---

## 3. Управление из Verse — `vfx_spawner_device`

```verse
EffectEnabledEvent  : listenable(payload)
EffectDisabledEvent : listenable(payload)

Enable():void          # старт looping-эффекта
Disable():void         # стоп
Restart():void         # перезапуск; для Burst — ВЫСТРЕЛ one-shot

# из creative_object:
TeleportTo[](Position:vector3, Rotation:rotation):void    # failable (<decides>)
MoveTo(Position, Rotation, OverTime:float)<suspends>:move_to_result
GetTransform():transform
```

- **One-shot vs loop:** Effect Type в редакторе. One-shot = Burst + `Restart()`. Loop = `Enable()`/`Disable()`.
- `TeleportTo[...]` — failable, в `if`. `MoveTo` — async (в `spawn{}`).
- **Niagara-хэндл/параметры из Verse НЕДОСТУПНЫ** (см. §5). Управляешь через Enable/Disable/Restart и перемещение устройства.

**Per-player VFX** (паттерн из офиц. Prop Hunt): **по VFX Spawner на игрока** в массиве, каждый кадр
`TeleportTo` устройство к своему игроку:
```verse
@editable VFXDevice : vfx_spawner_device = vfx_spawner_device{}
Activate(Transform : transform):void=
    if (VFXDevice.TeleportTo[Transform.Translation + Offset, Transform.Rotation]):
        VFXDevice.Enable()
```

---

## 4. Привязка к пропам/игрокам/NPC, движение, тайминг

Нативной «привязки к кости» для VFX **нет** — приближаешь позиционированием устройства:
- **в точке:** `TeleportTo[Location, IdentityRotation()]`;
- **на игроке:** каждый тик `TeleportTo` к `fort_character.GetTransform()`;
- **на пропе/NPC:** `TeleportTo` к их `GetTransform()`;
- **движущийся (трейл):** `MoveTo` или родитель VFX Spawner к **Prop Mover device**;
- **тайминг:** подписка на событие → `Restart()`/`Enable()` (или Direct Event Binding).

---

## 5. ⚠️ Niagara user-параметры (цвет, масштаб) — UEFN vs UE

Самое большое ограничение:
- В полном UE параметры ставят в рантайме (`SetColorParameter`…). **В UEFN из Verse/устройств — НЕЛЬЗЯ.**
- **Цвет:** опция **Colorize VFX + Custom Color** (в редакторе).
- **Масштаб/др. в рантайме:** единственный путь — **Level Sequence** с треками user-параметров → проиграть через Cinematic Sequence Device из Verse (косвенно, громоздко).
- **Вывод:** параметры — **bake-time, не runtime**. «Красный взрыв vs синий» = два разных VFX Spawner/Niagara, а не один параметризованный.

---

## 6. Паттерны
- **Взрыв на элиминации:** Burst + Explosion; на событии смерти `TeleportTo` к месту + `Restart()`.
- **Искра подбора:** loop-VFX, `Enable()` у предмета, `Disable()` (+ Clear Particles) при подборе.
- **Трейл:** VFX Spawner на Prop Mover или `MoveTo` по пути.
- **Эмбиент:** loop-VFX + Enabled on Phase, без Verse; область — через Visible to Team/Class.

---

## 7. Лимиты, перф, публикация
- **Нет рантайм-параметров Niagara из Verse** — гоча №1.
- **Нет attach-to-bone** — репозиционируешь устройство (дорого при масштабе: устройство на игрока + TeleportTo каждый тик).
- **Бюджет памяти** UEFN жёсткий — следи за числом частиц, GPU/CPU-эмиттерами, overdraw, числом VFX Spawner (Optimize / Memory Calculator).
- **Content Validation** блокирует неподдерживаемое (Color Curves, Engine Content) — смотри Error Log.
- «VFX не спавнится» обычно из-за phase/visibility/team-class или Burst (нужен `Restart`, не `Enable`).

---

## Разбор примера (`explosion_on_event_device.verse`)
- VFX Spawner (Effect Type=Burst) + триггер + проп.
- На триггере `TeleportTo` к пропу → `Restart()` (выстрел burst). Цвет — опцией Colorize, не из кода.

---

## Источники
- vfx_spawner_device (Verse API): https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/vfx_spawner_device
- Effects and Particle Systems: https://dev.epicgames.com/documentation/en-us/fortnite/effects-and-particle-systems-in-unreal-editor-for-fortnite
- VFX Spawner device (Creative): https://dev.epicgames.com/documentation/en-us/fortnite/using-vfx-spawner-devices-in-fortnite-creative
- Prop Hunt 02 — VFX on Players: https://dev.epicgames.com/documentation/en-us/fortnite/prop-hunt-02-playing-visual-effects-on-players-in-unreal-editor-for-fortnite
- Niagara in UEFN (курс): https://dev.epicgames.com/community/learning/courses/7DG/fortnite-niagara-in-uefn
- Control VFX Spawner with Verse: https://dev.epicgames.com/community/learning/tutorials/96bb/fortnite-control-a-vfx-spawner-device-with-verse-in-uefn

> ⚠️ «VFX Creator device» / «Visual Effect Powered device» как отдельных устройств в текущем API нет —
> актуальное устройство это **VFX Spawner**. Ограничение «нет Niagara-параметров из Verse» — на конец 2025;
> сверяйся со свежими release notes (Epic часто добавляет API).
