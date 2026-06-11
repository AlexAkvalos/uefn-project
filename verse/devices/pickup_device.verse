# Переиспользуемое устройство-подбираемое (single responsibility).
# Знает ТОЛЬКО про себя: когда его подобрали — публикует событие Collected.
# Ничего не знает про счёт/победу — за это отвечает score_manager_device.
# Это и есть «слабая связанность» (decoupling): связь идёт через события, не через прямые вызовы.

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

pickup_device := class(creative_device):

    # @editable с ToolTip — опция видна и подписана в панели Details редактора.
    # Хорошее значение по умолчанию: устройство работает «из коробки».
    @editable{ ToolTip := "Сколько очков даёт этот подбираемый предмет." }
    PointValue : int = 10

    @editable{ ToolTip := "Триггер, который ловит подбор предмета игроком." }
    CollectTrigger : trigger_device = trigger_device{}

    # Собственное ПУБЛИЧНОЕ событие. Payload — кортеж (кто подобрал, сколько очков).
    # Кто угодно может подписаться, не трогая внутренности устройства.
    Collected<public> : event(tuple(agent, int)) = event(tuple(agent, int)){}

    OnBegin<override>()<suspends>:void=
        # Sleep(0.0) — пропускаем один кадр, чтобы editable-ссылки точно
        # успели проинициализироваться (классическая гоча OnBegin).
        Sleep(0.0)
        CollectTrigger.TriggeredEvent.Subscribe(OnCollect)

    # Триггер отдаёт ?agent — может быть пусто, поэтому аккуратно разворачиваем.
    OnCollect(MaybeAgent : ?agent):void=
        if (Agent := MaybeAgent?):
            Collected.Signal((Agent, PointValue))   # публикуем — не знаем, кто слушает
            CollectTrigger.Disable()                # одноразовый подбор
