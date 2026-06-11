# Пример: физический импульс — запускает проп и отбрасывает игроков в зоне.
# Требует включённой Beta-физики (Project Settings → Beta Access → Physics) и
# у пропа компонент FortPhysics + Simulate Physics (или ставим dynamic из кода).
#
# ⚠️ Силы/импульсы МОЛЧА игнорируются на не-dynamic пропах/персонажах — частая причина «ничего не происходит».
#    Единицы: масса кг, скорость м/с, сила Н, импульс Н·с (в метрах, не см).

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

physics_launcher := class(creative_device):

    @editable{ ToolTip := "Проп для запуска (FortPhysics + Simulate Physics)." }
    Target : creative_prop = creative_prop{}

    @editable{ ToolTip := "Триггер запуска." }
    LaunchTrigger : trigger_device = trigger_device{}

    @editable{ ToolTip := "Зона: на входе игрока — отбрасываем его." }
    BlastZone : volume_device = volume_device{}

    @editable{ ToolTip := "Сила импульса запуска, Н·с." }
    LaunchImpulseMagnitude : float = 5000.0

    @editable{ ToolTip := "Сила отбрасывания игрока, Н·с." }
    KnockbackForce : float = 8000.0

    OnBegin<override>()<suspends>:void=
        LaunchTrigger.TriggeredEvent.Subscribe(OnLaunch)
        BlastZone.AgentEntersEvent.Subscribe(OnAgentEntered)

    OnLaunch(MaybeAgent : ?agent):void=
        # Гарантируем, что проп физический, иначе импульс ничего не сделает.
        Target.SetDynamic(true)
        # Запуск вверх-вперёд.
        LaunchDir := vector3{ X := 0.4, Y := 0.0, Z := 1.0 }
        Target.ApplyLinearImpulse(LaunchDir * LaunchImpulseMagnitude)
        # Закрутка (угловой импульс — только у пропов, не у персонажей).
        Target.ApplyAngularImpulse(vector3{ X := 0.0, Y := 200.0, Z := 0.0 })
        Print("Проп запущен. Масса = {Target.GetMass()} кг")

    # Отбрасываем игрока, вошедшего в зону.
    OnAgentEntered(Agent : agent):void=
        if (Char := Agent.GetFortCharacter[]):
            Mass := Char.GetMass()
            KnockDir := vector3{ X := 1.0, Y := 0.0, Z := 0.6 }
            # Масштабируем на массу — чтобы тяжёлые/лёгкие чувствовались одинаково.
            Char.ApplyLinearImpulse(KnockDir * KnockbackForce * Mass)
            Print("Игрок отброшен, масса = {Mass} кг")
