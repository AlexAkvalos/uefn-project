# Устройство-менеджер: владеет ПРАВИЛАМИ и общим состоянием.
# Подписывается на события подбираемых предметов (pickup_device) и ведёт счёт по игрокам.
# Паттерн «manager»: один координатор + много «тупых» переиспользуемых воркеров.

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

score_manager_device := class(creative_device):

    # Массив, а не отдельное поле на каждый предмет — так масштабируется.
    @editable{ ToolTip := "Все предметы, за которыми следит этот менеджер." }
    Pickups : []pickup_device = array{}

    @editable{ ToolTip := "Сколько очков нужно для победы." }
    WinThreshold : int = 100

    # Состояние на каждого игрока — в map с ключом agent.
    var Scores : [agent]int = map{}

    # Публичное событие победы — пусть другие системы реагируют (UI, концовка и т.д.).
    Won<public> : event(agent) = event(agent){}

    OnBegin<override>()<suspends>:void=
        Sleep(0.0)
        # Падаем «громко», а не молча: если предметы не привязаны — это ошибка дизайнера.
        if (Pickups.Length = 0):
            Print("score_manager: не привязано ни одного pickup!")
        # Слабая связанность: подписываемся на события каждого предмета.
        for (P : Pickups):
            P.Collected.Subscribe(OnPickupCollected)

    OnPickupCollected(Data : tuple(agent, int)):void=
        Player := Data(0)
        Points := Data(1)
        Add(Player, Points)

    # Прибавить очки игроку и проверить победу.
    Add(Player : agent, Points : int):void=
        var Total : int = Points
        if (Existing := Scores[Player]):
            set Total += Existing
        if (set Scores[Player] = Total) {}
        Print("Счёт игрока: {Total}")
        if (Total >= WinThreshold):
            Won.Signal(Player)
