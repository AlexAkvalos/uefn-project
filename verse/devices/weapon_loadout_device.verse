# Устройство-лоадаут: по нажатию кнопки выдаёт игроку оружие через Item Granter.
# Это НАДЁЖНЫЙ device-based паттерн выдачи оружия (работает на всех версиях).
# Для НОВЫХ Custom Weapon Templates (v41.00) выдача идёт через Custom Items API
# (AddItem / AddItemDistribute) — см. docs/16-custom-weapons.md.
#
# Идея: каждой кнопке соответствует свой Item Granter (в нём настроено оружие в редакторе).

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

weapon_loadout_device := class(creative_device):

    # Кнопки выбора лоадаута и соответствующие гранторы — парами по индексу.
    @editable{ ToolTip := "Кнопки выбора лоадаута (по индексу совпадают с Granters)." }
    LoadoutButtons : []button_device = array{}

    @editable{ ToolTip := "Item Granter'ы с настроенным оружием (по индексу = кнопкам)." }
    Granters : []item_granter_device = array{}

    OnBegin<override>()<suspends>:void=
        Sleep(0.0)
        # Привязываем каждую кнопку к её индексу через замыкание.
        for (Index -> Button : LoadoutButtons):
            Button.InteractedWithEvent.Subscribe(MakeHandler(Index))

    # Возвращает обработчик, «запомнивший» индекс лоадаута.
    MakeHandler(Index : int)(Agent : agent):void =
        GrantLoadout(Agent, Index)

    GrantLoadout(Agent : agent, Index : int):void=
        # Гард: грантор с таким индексом должен существовать.
        if (Granter := Granters[Index]):
            Granter.GrantItem(Agent)
            Print("Выдан лоадаут {Index}")
        else:
            Print("Нет грантора для лоадаута {Index}")
