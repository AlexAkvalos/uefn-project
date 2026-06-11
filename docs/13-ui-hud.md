# 13. Топовый HUD и UI на Verse (UMG)

Как делать качественный кастомный интерфейс в UEFN. Весь UI пишется кодом на Verse (визуального
редактора виджетов нет). Рабочий пример: [`../verse/ui/custom_hud_device.verse`](../verse/ui/custom_hud_device.verse).

> ⚠️ UMG-API живёт под путём `/UnrealEngine.com/Temporary/UI` — слово **Temporary** не случайно.
> Epic держит его стабильным, но может поменять на апдейтах движка. Тестируй после обновлений.

---

## Модули (imports)

```verse
using { /Fortnite.com/UI }                          # GetPlayerUI, button_loud/button_quiet
using { /UnrealEngine.com/Temporary/UI }            # canvas, text_block, anchors, margin…
using { /UnrealEngine.com/Temporary/SpatialMath }   # vector2
using { /Verse.org/Colors }                         # color, NamedColors
using { /Verse.org/Simulation }
```

---

## 1. Базовый API

`GetPlayerUI[Player]` — **failable** (квадратные скобки!), возвращает `player_ui` —
персональный «холст» каждого игрока. Вызывается в контексте провала (`if`):

```verse
if (PlayerUI := GetPlayerUI[Player]):
    MyText : text_block = text_block{ DefaultText := MyMessage() }
    PlayerUI.AddWidget(MyText)
```

`AddWidget` с настройкой слота (режим ввода, z-order):

```verse
PlayerUI.AddWidget(MyWidget, player_ui_slot{ InputMode := ui_input_mode.All })
```

- `ui_input_mode.None` — косметический HUD, **не перехватывает ввод** (для HUD — это).
- `ui_input_mode.All` — ловит мышь/клавиатуру (для меню с кнопками).

**Удаление** — нужно хранить ссылку на добавленный виджет: `PlayerUI.RemoveWidget(MyWidget)`.

---

## 2. Виджеты: контейнеры и контент

| Виджет | Роль | Слот |
| --- | --- | --- |
| `canvas` | свободное позиционирование (anchors+offsets) | `canvas_slot` |
| `stack_box` | список по вертикали/горизонтали | `stack_box_slot` |
| `overlay` | слои друг над другом | `overlay_slot` |
| `button_loud` / `button_quiet` | кнопка (один потомок), `.OnClick()` | `button_slot` |
| `text_block` | текст | — |
| `color_block` | заливка цветом (полоски, фоны) | — |
| `texture_block` | картинка-текстура | — |
| `material_block` | материал (анимация/шейдер) | — |

**Канвас:**
```verse
MyCanvas : canvas = canvas:
    Slots := array:
        canvas_slot:
            Anchors := anchors{ Minimum := vector2{X:=0.0,Y:=0.0}, Maximum := vector2{X:=1.0,Y:=0.0} }
            Offsets := margin{ Top := 100.0 }
            SizeToContent := true
            Widget := ScoreWidget
```

**Stack box** (списки/строки — сами расставляются):
```verse
stack_box:
    Orientation := orientation.Vertical
    Slots := array:
        stack_box_slot:
            HorizontalAlignment := horizontal_alignment.Left
            Padding := margin{ Bottom := 20.0 }
            Widget := WidgetTitle
```

**Overlay** (фон + контент — паттерн «карточка»):
```verse
overlay:
    Slots := array:
        overlay_slot{ Widget := WidgetBackground }   # задний слой (color_block/texture_block)
        overlay_slot{ Widget := ContentStack }        # передний слой
```

**Контент:**
```verse
text_block{ DefaultText := Title(), DefaultTextColor := NamedColors.RoyalBlue, DefaultJustification := text_justification.Center }
color_block{ DefaultColor := NamedColors.Black, DefaultOpacity := 0.7 }
texture_block{ DefaultImage := MyTexture, DefaultDesiredSize := vector2{X:=512.0,Y:=512.0} }
```

Текстуры/материалы подключаются через **Asset Reflection** (ПКМ по ассету → он становится
Verse-идентификатором). В рантайме меняй картинку через `SetImage(...)`.

---

## 3. Позиционирование (самое важное)

У `canvas_slot`:

| Поле | Что задаёт |
| --- | --- |
| `Anchors` | **точка на канвасе** (0..1): `(0,0)` — лево-верх, `(1,1)` — право-низ, `(0.5,0.5)` — центр |
| `Alignment` | **точка-якорь на самом виджете** (0..1): какой угол виджета «сядет» на anchor |
| `Offsets` | `margin{Top,Left,Right,Bottom}` — сдвиг в пикселях (в виртуальном пространстве 1080p) |
| `SizeToContent` | `true` — виджет своего размера; `false` — размер задаётся прямоугольником offsets |
| `ZOrder` | выше = поверх |

Если `Anchors.Minimum != Maximum` — виджет **растягивается** между ними (адаптивно).

**Рецепты:**
```verse
# Ровно по центру: anchor (0.5,0.5) И alignment (0.5,0.5)
# Право-верх с отступом 40px: anchor (1,0), alignment (1,0), Offsets{Top:=40, Right:=40}
# Фон на весь экран: anchor Min(0,0)–Max(1,1)
```
Мантра Epic: **Anchors → Alignment → подгонка Offsets → SizeToContent.** Центрируй через alignment, не через padding.

---

## 4. Реактивное обновление

В UEFN нет авто-биндинга как в «большом» UE MVVM — обновляешь **императивно**:
хранишь ссылку на виджет и зовёшь сеттеры.

```verse
ScoreWidget.SetText(ScoreMessage(NewScore))   # обновить текст
ItemSlot.SetImage(GetItemImage(Item))         # обновить картинку
```

- **Весь текст — `message`** (`<localizes>`), не `string`. Для рантайм-строки оберни:
  `StringToMessage<localizes>(S:string):message = "{S}"`.
- Для непрерывных значений (скорость, таймер) — цикл с разумной частотой:
  ```verse
  loop:
      View.SetScore(CurrentScore)
      Sleep(0.1)   # 10 Гц для HUD достаточно; НЕ обновляй каждый кадр
  ```
- Для чистой архитектуры — паттерн **view-класс** + подписка на `event()` (MVVM-стиль).

---

## 5. Per-player, показ/скрытие, кнопки

- **Общего экрана нет** — у каждого игрока свой `player_ui`. «Общий HUD» = пройтись по всем
  игрокам и добавить каждому **свой экземпляр** виджета.
- 🐛 **Главная ошибка:** шарить один инстанс виджета между игроками → обновления конфликтуют,
  удаление у одного ломает у другого. Создавай новый виджет на игрока и храни в `[agent]…`/`[player]…` map.
- **Кнопки:**
  ```verse
  MyButton.OnClick().Subscribe(OnClicked)   # подписка ОДИН раз, не в цикле!
  OnClicked(Message : widget_message):void = ...   # Message.Player — кто нажал
  ```
  Кнопкам нужен `InputMode := ui_input_mode.All`, иначе клики не дойдут.

---

## 6. Скрыть стандартный HUD + HUD транспорта

**Скрыть дефолтные элементы** (современный per-player способ; старый `HideHUDElements` — deprecated и бьёт по всем):
```verse
if (FortChar := Agent.GetFortCharacter[]):
    HUDController := FortChar.GetPlayspace().GetHUDController()
    ElementsToHide : []hud_element_identifier = array:
        creative_hud_identifier_health{}
        creative_hud_identifier_equipped_item{}
        # creative_hud_identifier_all{}   # скрыть всё
    HUDController.HideElements(ElementsToHide)
```
Есть `ShowElements` / `ResetElementVisibility`. Можно поставить **HUD Controller device** в редакторе.

**HUD транспорта (скорость/топливо/буст):** богатого публичного API телеметрии у `fort_vehicle`
немного, поэтому профи обычно **считают скорость сами** по дельте позиции за тик
(`Distance(NowPos, LastPos)/DeltaTime`), а топливо/буст ведут как своё `var:float`-состояние.

---

## 7. Best practices (что делает UI топовым)

- **Дизайнь в 1080p-пространстве** — Epic авто-масштабирует на реальное разрешение (мобайл↔4K).
- **Якори к краям, не к абсолютным пикселям** — элемент в углу `(1,0)` останется в углу на любом соотношении сторон.
- **`overlay` + `color_block`** для панелей вместо больших текстур — дешевле и чётче.
- **Мобилки (2026):** Mobile Preview с симуляцией тача на ПК, крупные тап-зоны, учёт safe-area (вырезы/скругления).
- **Производительность:** обновляй **по изменению** или 5–10 Гц; **переиспользуй** виджеты (не пересоздавай канвас); меньше `material_block`; подписывайся на события **один раз**.
- **Локализация с первого дня** — весь текст через `<localizes>`.

---

## 8. Частые ошибки

1. `string` вместо `message` в `SetText`/`DefaultText` — не скомпилируется.
2. Шаринг одного виджета между игроками → конфликты обновлений/удаления.
3. Забыл `ui_input_mode.All` на меню → кнопки не кликаются (и наоборот: `.All` на пассивном HUD крадёт ввод).
4. Путаница **Anchors vs Alignment** (точка на канвасе ≠ точка на виджете).
5. Не сохранил ссылку на виджет → нельзя `RemoveWidget`.
6. Повторная подписка на `OnClick()` в цикле → дубли обработчиков.
7. Обновление текста каждый кадр → лаги и мерцание.
8. Deprecated `HideHUDElements` вместо `GetHUDController().HideElements()`.

---

## Видео и open-source примеры

- Best Practices for Custom UI (2026): https://www.youtube.com/watch?v=7fdcnSO4wVY
- Custom Multiplayer HUD with Verse: https://www.youtube.com/watch?v=eg2rK-hDXDo
- Add/Remove Widget (текстуры/текст): https://www.youtube.com/watch?v=F9K9dRN1ur0
- Hide HUD via Verse: https://www.youtube.com/watch?v=Qg20Bt2HUmY
- MVVM-пример: https://github.com/eiei114/uefn_mvp_sample/blob/main/player_view.verse
- stack_box/overlay/per-player: https://github.com/futouyiba/UefnVerseCode/blob/main/shared.verse
- Item Shop UI (texture_block): https://github.com/tuurGevers/uefn-timer-lib/blob/master/ItemShop.verse

## Официальная документация

- Creating In-Game UI in Verse: https://dev.epicgames.com/documentation/en-us/fortnite/creating-in-game-ui-in-verse
- Creating and Removing Widgets: https://dev.epicgames.com/documentation/en-us/fortnite/creating-and-removing-widgets-in-unreal-editor-for-fortnite
- Positioning Widgets on the Screen: https://dev.epicgames.com/documentation/en-us/fortnite/positioning-widgets-on-the-screen-in-unreal-editor-for-fortnite
- Removing/Controlling the Default HUD: https://dev.epicgames.com/documentation/fortnite/removing-and-controlling-the-fortnite-default-hud-in-unreal-editor-for-fortnite
- Verse API (UI module): https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/unrealenginedotcom/temporary/ui

> Примечание о точности: некоторые точные имена сеттеров (`SetVisibility`/`SetEnabled`/`ZOrder`/
> поля `player_ui_slot`, список `creative_hud_identifier_*`) на справке Epic рендерятся через JS —
> сверяйся с актуальным API Reference перед релизом.
