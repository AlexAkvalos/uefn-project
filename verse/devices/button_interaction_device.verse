using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Устройство начисляет очки игроку, который нажал на кнопку.
# Демонстрирует:
#   - @editable свойства (настраиваются в редакторе UEFN);
#   - подписку на событие устройства (InteractedWithEvent);
#   - изменяемое состояние через `var`.
button_interaction_device := class(creative_device):

    # @editable — свойство видно и настраивается в панели Details в UEFN.
    # Сюда в редакторе нужно перетащить устройство-кнопку (button_device).
    @editable
    Button : button_device = button_device{}

    # Сколько очков давать за одно нажатие. Тоже настраивается в редакторе.
    @editable
    PointsPerPress : int = 10

    # Изменяемое состояние. `var` — переменная, которую можно менять через `set`.
    var Score : int = 0

    OnBegin<override>()<suspends>:void=
        # Подписываемся на событие «по кнопке взаимодействовали».
        # При срабатывании вызовется наш метод OnButtonPressed.
        Button.InteractedWithEvent.Subscribe(OnButtonPressed)

    # agent — это «агент», обычно игрок, совершивший действие.
    OnButtonPressed(Agent : agent):void=
        set Score += PointsPerPress
        Print("Кнопка нажата! Текущий счёт: {Score}")
