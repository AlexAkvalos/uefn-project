# Каркас экономики для игры жанра "Steal a Brainrot" (tycoon + кража юнитов).
# Показывает СТАТ-ТАБЛИЦУ юнитов, пассивный доход (сумма по юнитам игрока),
# безопасную покупку через <decides><transacts> и персистентность валюты.
#
# Это СКЕЛЕТ: размещение пропов-юнитов на базе и механику кражи добавляешь поверх
# (см. docs/19-steal-a-brainrot.md). Имена ассетов пропов подставь свои.

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Редкость юнита.
unit_rarity := enum { Common, Rare, Epic, Legendary, Mythic, BrainrotGod }

# Описание одного юнита («бреинрота»).
unit_def := struct:
    Name       : string
    Rarity     : unit_rarity
    Cost       : int          # цена покупки
    IncomeRate : int          # доход за тик

# Стат-таблица — список доступных юнитов (PropAsset подставь отдельно при размещении).
UnitTable : []unit_def = array:
    unit_def{ Name := "Tung Tung",  Rarity := unit_rarity.Common,    Cost := 100,   IncomeRate := 2 }
    unit_def{ Name := "Tralalero",  Rarity := unit_rarity.Rare,      Cost := 750,   IncomeRate := 12 }
    unit_def{ Name := "Sahur",      Rarity := unit_rarity.Legendary, Cost := 12000, IncomeRate := 140 }

# Сохраняемые данные игрока (одна persistable-структура — экономно по лимиту weak_map).
brainrot_save := class<final><persistable>:
    Version  : int = 1
    Currency : int = 0
    # индексы купленных юнитов из UnitTable
    OwnedUnitIds : []int = array{}

# Персистентность (module scope).
var SaveMap : weak_map(player, brainrot_save) = map{}

brainrot_income_device := class(creative_device):

    @editable{ ToolTip := "Кнопки покупки (по индексу = UnitTable)." }
    BuyButtons : []button_device = array{}

    @editable{ ToolTip := "Табло баланса игрока." }
    Billboard : billboard_device = billboard_device{}

    @editable{ ToolTip := "Интервал начисления дохода, сек." }
    IncomeInterval : float = 1.0

    # Живое состояние в рантайме (зеркало сохранения).
    var PlayerData : [player]brainrot_save = map{}

    OnBegin<override>()<suspends>:void=
        Sleep(0.0)
        GetPlayspace().PlayerAddedEvent().Subscribe(OnJoined)
        for (P : GetPlayspace().GetPlayers()):
            OnJoined(P)
        # Кнопки покупки — spawn{} на каждую, т.к. в Verse нет замыканий по переменной цикла.
        for (Index -> Button : BuyButtons):
            spawn { WatchBuy(Button, Index) }
        # Цикл пассивного дохода.
        spawn { IncomeLoop() }

    OnJoined(Player : player):void=
        # Загрузить сохранение или создать новое.
        if (Saved := SaveMap[Player]):
            if (set PlayerData[Player] = Saved) {}
        else:
            Fresh := brainrot_save{}
            if (set SaveMap[Player] = Fresh) {}
            if (set PlayerData[Player] = Fresh) {}
        Refresh(Player)

    # Сумма дохода по всем юнитам игрока.
    IncomeOf(Data : brainrot_save):int=
        var Sum : int = 0
        for (Id : Data.OwnedUnitIds, Def := UnitTable[Id]):
            set Sum += Def.IncomeRate
        Sum

    IncomeLoop()<suspends>:void=
        loop:
            Sleep(IncomeInterval)
            for (Player -> Data : PlayerData):
                NewCurrency := Data.Currency + IncomeOf(Data)
                Updated := brainrot_save:
                    Version := Data.Version
                    Currency := NewCurrency
                    OwnedUnitIds := Data.OwnedUnitIds
                if (set PlayerData[Player] = Updated) {}
                if (set SaveMap[Player] = Updated) {}
                Refresh(Player)

    WatchBuy(Button : button_device, Index : int)<suspends>:void=
        loop:
            Agent := Button.InteractedWithEvent.Await()
            if (Player := player[Agent]):
                TryBuy(Player, Index)

    TryBuy(Player : player, Index : int):void=
        if:
            Def  := UnitTable[Index]
            Data := PlayerData[Player]
            Data.Currency >= Def.Cost          # хватает денег — иначе ветка не выполнится
        then:
            Updated := brainrot_save:
                Version := Data.Version
                Currency := Data.Currency - Def.Cost
                OwnedUnitIds := Data.OwnedUnitIds + array{ Index }
            if (set PlayerData[Player] = Updated) {}
            if (set SaveMap[Player] = Updated) {}
            Print("Куплен {Def.Name}, баланс {Updated.Currency}")
            Refresh(Player)
            # тут: разместить проп юнита в следующий свободный слот базы

    BalanceText<localizes>(Currency : int):message = "Баланс: {Currency}"

    Refresh(Player : player):void=
        if (Data := PlayerData[Player]):
            Billboard.SetText(BalanceText(Data.Currency), Player)
