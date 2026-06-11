# Подключаем модули UEFN.
# /Fortnite.com/Devices            — устройства Fortnite (creative_device и т.д.)
# /Verse.org/Simulation            — базовые типы и логика симуляции
# /UnrealEngine.com/Temporary/Diagnostics — Print() для вывода в лог
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Простейшее устройство на Verse, которое можно перетащить на уровень.
# class(creative_device) делает его полноценным устройством UEFN.
hello_world_device := class(creative_device):

    # OnBegin вызывается, когда устройство стартует в запущенной игре.
    # <override>  — переопределяем метод базового класса creative_device.
    # <suspends>  — функция может «приостанавливаться» (async-логика, Sleep и т.п.).
    OnBegin<override>()<suspends>:void=
        Print("Hello, world!")

        # {2 + 2} — интерполяция строки: выражение в фигурных скобках
        # вычисляется до вывода. В лог попадёт: "2 + 2 = 4".
        Print("2 + 2 = {2 + 2}")
