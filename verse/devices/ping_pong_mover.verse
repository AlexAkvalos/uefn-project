# Пример: плавно двигает проп туда-обратно в цикле через creative_prop.MoveTo.
# MoveTo асинхронна (<suspends>) и возвращается только по прибытии — это и есть «двигатель» цикла.
# ⚠️ RotateTo у creative_prop НЕТ: поворот делается через MoveTo с новой rotation.

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

ping_pong_mover := class(creative_device):

    @editable{ ToolTip := "Проп, который двигаем (привязать в редакторе)." }
    Prop : creative_prop = creative_prop{}

    @editable{ ToolTip := "Смещение в см (куда уезжает проп)." }
    Offset : vector3 = vector3{X := 0.0, Y := 500.0, Z := 0.0}

    @editable{ ToolTip := "Время в одну сторону, сек." }
    TravelTime : float = 2.0

    OnBegin<override>()<suspends>:void=
        StartTransform := Prop.GetTransform()
        StartPos := StartTransform.Translation
        Rot      := StartTransform.Rotation
        EndPos   := StartPos + Offset
        loop:
            Prop.MoveTo(EndPos,   Rot, TravelTime)   # приостановка до прибытия
            Prop.MoveTo(StartPos, Rot, TravelTime)   # обратно; цикл повторяется
