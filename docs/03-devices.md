# 03. Устройства и события

В UEFN игровая логика строится вокруг **устройств** (devices). Verse-устройство — это класс,
наследующий `creative_device`.

## Анатомия устройства

```verse
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

my_device := class(creative_device):

    @editable
    SomeSetting : int = 5

    OnBegin<override>()<suspends>:void=
        Print("Устройство запущено")
```

- `class(creative_device)` — делает класс устройством, которое можно перетащить на уровень.
- `OnBegin` — точка входа, выполняется при старте игры.
- `@editable` — выносит свойство в панель **Details** редактора UEFN.

## @editable свойства

Свойства с `@editable` настраиваются прямо в редакторе без правки кода:

```verse
@editable
PointsPerPress : int = 10           # число

@editable
Button : button_device = button_device{}   # ссылка на другое устройство
```

Ссылочные свойства (как `button_device`) нужно «привязать» в редакторе:
выбрать устройство в выпадающем списке свойства или перетащить с уровня.

## Подписка на события

Устройства публикуют события (events). Подписка — через `Subscribe`:

```verse
OnBegin<override>()<suspends>:void=
    Button.InteractedWithEvent.Subscribe(OnButtonPressed)

OnButtonPressed(Agent : agent):void=
    Print("Нажал: игрок")
```

Частые события устройств:

| Устройство | Событие | Когда срабатывает |
| --- | --- | --- |
| `button_device` | `InteractedWithEvent` | игрок нажал кнопку |
| `trigger_device` | `TriggeredEvent` | сработал триггер |
| `player_spawner_device` | `SpawnedEvent` | игрок заспавнился |
| `damage_volume_device` | — | зона урона |

Полный список — в [Verse API Reference](https://dev.epicgames.com/documentation/en-us/uefn/verse-api).

## Поиск устройств и игроков во время игры

```verse
using { /Fortnite.com/Playspaces }

OnBegin<override>()<suspends>:void=
    Playspace := GetPlayspace()
    AllPlayers := Playspace.GetPlayers()
    Print("Игроков на старте: {AllPlayers.Length}")
```

## Примеры в этом репозитории

- [`hello_world_device.verse`](../verse/devices/hello_world_device.verse) — минимальное устройство.
- [`button_interaction_device.verse`](../verse/devices/button_interaction_device.verse) — кнопка + очки.
- [`round_manager_device.verse`](../verse/devices/round_manager_device.verse) — таймер раунда с `loop`/`Sleep`.

## Полезные ссылки

- Создание устройства на Verse: https://dev.epicgames.com/documentation/en-us/fortnite/create-your-own-device-using-verse-in-unreal-editor-for-fortnite
- Editable-свойства: https://dev.epicgames.com/documentation/en-us/fortnite/editable-properties-in-verse
- Кодинг взаимодействий: https://dev.epicgames.com/documentation/en-us/fortnite/coding-device-interactions-in-verse
