# Пример КОМПОНЕНТА Scene Graph (не устройства!).
# Компонент навешивается на сущность (entity) и даёт ей поведение.
# Это современный подход UEFN: entity + components вместо одного большого creative_device.

using { /Verse.org }
using { /Verse.org/Native }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SceneGraph }
using { /UnrealEngine.com/Temporary/Diagnostics }

# class<final_super>(component) — наследуемся от базового component.
# Сущность с этим компонентом будет периодически скрываться и появляться.
disappear_on_loop_component := class<final_super>(component):

    # Сколько секунд объект остаётся скрытым (настраивается в редакторе).
    @editable
    HiddenDuration : float = 1.0

    # Сколько секунд объект остаётся видимым.
    @editable
    VisibleDuration : float = 2.0

    # --- Жизненный цикл компонента ---
    # Порядок: Initialized → AddedToScene → BeginSimulation
    #          → EndSimulation → RemovingFromScene → Uninitializing

    # Вызывается при старте симуляции (аналог OnBegin у устройства).
    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Print("disappear_on_loop_component: симуляция началась")

    # Основная логика. <suspends> — может приостанавливаться (async),
    # автоматически отменяется при удалении компонента.
    OnSimulate<override>()<suspends>:void =
        loop:
            Sleep(VisibleDuration)
            # TODO: здесь скрыть меш сущности (например, через mesh-компонент)
            Print("Скрываю объект на {HiddenDuration} сек")
            Sleep(HiddenDuration)
            Print("Показываю объект")

    # Вызывается при остановке симуляции — здесь делаем очистку.
    OnEndSimulation<override>():void =
        (super:)OnEndSimulation()
        Print("disappear_on_loop_component: симуляция завершена")
