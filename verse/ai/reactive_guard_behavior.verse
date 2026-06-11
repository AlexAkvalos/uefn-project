# Пример КАСТОМНОГО поведения NPC-стража через Scene Graph AI-компоненты (v39.00).
# Страж патрулирует, замечает игроков через awareness-компонент и атакует через actions-компонент.
#
# Подключение: создай Verse-файл по шаблону "NPC Behavior", собери код,
# затем в NPC Spawner device в поле "NPC Behavior" укажи этот класс
# (или задай его в CharacterDefinition).
#
# Современный путь (v39): npc_behavior.GetEntity[] -> Entity.GetComponent[...]
# вместо старых интерфейсов navigable/focusable/leashable.

using { /Fortnite.com/AI }
using { /Verse.org/SceneGraph }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

reactive_guard_behavior := class(npc_behavior):

    # OnBegin вызывается, когда NPC добавлен в симуляцию (заспавнен и готов).
    OnBegin<override>()<suspends>:void=
        # 1. Берём сущность NPC — это шлюз к Scene Graph-компонентам.
        #    GetEntity[] и GetComponent[...] — failable (квадратные скобки).
        if:
            Entity    := GetEntity[]
            Actions   := Entity.GetComponent[guard_actions_component]
            Awareness := Entity.GetComponent[guard_awareness_component]
        then:
            # 2. Реакции на восприятие.
            Awareness.SeeTargetEvent.Subscribe(OnTargetSeen)
            Awareness.PrimaryThreatChangeEvent.Subscribe(OnThreatChanged)
            Awareness.ForgetTargetEvent.Subscribe(OnTargetForgotten)
            # 3. Пока никого не видим — патрулируем.
            Actions.RoamAround()

    # Сработало зрение — выбираем ближайшую цель и идём в бой.
    OnTargetSeen(Payload : payload):void=
        if:
            Entity    := GetEntity[]
            Actions   := Entity.GetComponent[guard_actions_component]
            Awareness := Entity.GetComponent[guard_awareness_component]
            Targets   := Awareness.DetectedTargets?
            Nearest   := FindNearestTarget[Entity, Targets]
        then:
            spawn { EngageTarget(Actions, Nearest.Target) }

    # Сменилась главная угроза — переключаемся на неё.
    OnThreatChanged(Payload : payload):void=
        if:
            Entity  := GetEntity[]
            Actions := Entity.GetComponent[guard_actions_component]
            Awr     := Entity.GetComponent[guard_awareness_component]
            Threat  := Awr.PrimaryThreat?     # ??npc_target_info — разворачиваем
            Info    := Threat?
        then:
            spawn { EngageTarget(Actions, Info.Target) }

    # Цель потеряна — возвращаемся к патрулю.
    OnTargetForgotten(Payload : payload):void=
        if:
            Entity  := GetEntity[]
            Actions := Entity.GetComponent[guard_actions_component]
        then:
            Actions.StopNavigation()
            Actions.RoamAround()

    # Подойти на дистанцию и атаковать.
    EngageTarget(Actions : guard_actions_component, TargetEntity : entity)<suspends>:void=
        Actions.Focus(TargetEntity)                       # повернуться к цели
        NavTarget := MakeNavigationTarget(TargetEntity)   # следовать за сущностью
        Actions.NavigateTo(NavTarget, movement_type.Running, 200.0, true)
        Actions.MoveInRangeToAttack()                     # сократить дистанцию
        Actions.Attack()                                  # требует обнаруженной цели

    # Хелпер: ближайшая цель по дистанции (по трансформам сущностей).
    FindNearestTarget(Self : entity, Targets : []npc_target_info)<transacts><decides>:npc_target_info=
        SelfPos := Self.GetGlobalTransform().Translation
        var Best : ?npc_target_info = false
        var BestDist : float = Inf
        for (T : Targets):
            Pos := T.Target.GetGlobalTransform().Translation
            D   := DistanceSquared(SelfPos, Pos)
            if (D < BestDist):
                set BestDist = D
                set Best = option{ T }
        Best?
