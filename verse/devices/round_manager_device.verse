using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Простой менеджер раундов: ведёт обратный отсчёт времени раунда
# и зацикливает раунды. Демонстрирует:
#   - асинхронный цикл с Sleep();
#   - <suspends>-функции;
#   - постоянно работающую игровую логику.
round_manager_device := class(creative_device):

    # Длительность одного раунда в секундах (настраивается в редакторе UEFN).
    @editable
    RoundDurationSeconds : float = 60.0

    OnBegin<override>()<suspends>:void=
        # Бесконечный игровой цикл. loop крутится, пока работает устройство.
        loop:
            RunRound()

    # Один раунд: отсчёт по секундам, затем завершение.
    RunRound()<suspends>:void=
        Print("=== Раунд начался! Длительность: {RoundDurationSeconds} сек ===")

        # Округляем длительность вниз до целого числа секунд для отсчёта.
        var SecondsLeft : int = Floor[RoundDurationSeconds] or 0

        loop:
            # Условие выхода из цикла — время вышло.
            if (SecondsLeft <= 0):
                break

            Print("Осталось секунд: {SecondsLeft}")
            Sleep(1.0)            # приостановка на 1 секунду
            set SecondsLeft -= 1

        Print("=== Раунд завершён ===")
