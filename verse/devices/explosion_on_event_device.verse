# Пример: one-shot VFX (взрыв) в точке пропа по событию игрока.
# Настройка в редакторе: VFX Spawner с Effect Type = Burst, Burst Visual Effect = Explosion,
# опц. Clear Particles on Disable = On. Привязать VFX Spawner, Trigger и Prop в @editable.
#
# ⚠️ One-shot = Effect Type=Burst в редакторе + Restart() в Verse (НЕ Enable).
#    Цвет VFX задаётся опцией Colorize VFX в Details — из Verse нельзя.
#    Niagara user-параметры из Verse НЕ ставятся (для красного/синего — два разных VFX).

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

explosion_on_event_device := class(creative_device):

    @editable{ ToolTip := "VFX Spawner с Effect Type = Burst." }
    ExplosionVFX : vfx_spawner_device = vfx_spawner_device{}

    @editable{ ToolTip := "Источник события (триггер)." }
    StartTrigger : trigger_device = trigger_device{}

    @editable{ ToolTip := "Проп, у которого появится взрыв." }
    TargetProp : creative_prop = creative_prop{}

    @editable
    HeightOffset : float = 100.0

    OnBegin<override>()<suspends>:void=
        StartTrigger.TriggeredEvent.Subscribe(OnTriggered)
        ExplosionVFX.EffectEnabledEvent.Subscribe(OnVFXEnabled)

    OnTriggered(MaybeAgent : ?agent):void=
        PlayExplosionAtProp()

    # Телепортируем burst-VFX к пропу, затем Restart() — выстрел one-shot.
    PlayExplosionAtProp():void=
        PropTransform := TargetProp.GetTransform()
        SpawnPos := PropTransform.Translation + vector3{ X := 0.0, Y := 0.0, Z := HeightOffset }
        # TeleportTo — failable (<decides>), оборачиваем в if.
        if (ExplosionVFX.TeleportTo[SpawnPos, PropTransform.Rotation]):
            ExplosionVFX.Restart()
        else:
            ExplosionVFX.Restart()    # фолбэк: на месте устройства

    OnVFXEnabled(InPayload : payload):void=
        Print("Взрыв сыгран")
