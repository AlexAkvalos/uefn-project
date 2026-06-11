# Пример CUSTOM ITEM «монетка» с подбором (Scene Graph + Custom Items & Inventory).
# Состоит из двух компонентов:
#   - coin_item_component  — делает сущность ПРЕДМЕТОМ (подкласс item_component);
#   - item_interactable_component — подбор: при взаимодействии кладёт предмет в инвентарь.
#
# Настройка сущности-монетки в Prefab Editor: mesh_component (модель монеты),
# transform_component, coin_item_component, description_component (Name="Монета"),
# icon_component (текстура), опц. stacking_component, и этот interactable.
# У игрока должна быть хотя бы одна подынвентарь под Inventory Root — иначе предмет некуда класть.
#
# ⚠️ Имена компонентов сменились в v40.20: item_details_component -> description_component,
#    item_icon_component -> icon_component. Ниже используется имя из официального туториала;
#    в v40.20+ читай description_component. Сверяй в Verse Explorer своей версии.

using { /Verse.org/Simulation }
using { /Verse.org/SceneGraph }
using { /UnrealEngine.com/Itemization }
using { /UnrealEngine.com/Temporary/Diagnostics }

# 1) Тип предмета — просто подкласс item_component со своими данными.
coin_item_component := class(item_component):
    Value : int = 1

# 2) Хелпер: получить корневой инвентарь игрока.
#    FindDescendantComponents находит все inventory_component в поддереве агента; [0] — корень.
GetInventoryRoot(Agent : agent)<decides><transacts>:inventory_component =
    Inventory := (for (I : Agent.FindDescendantComponents(inventory_component)) { I })[0]

DefaultInteractionMessage<localizes> : message = "Подобрать"

# 3) Подбор: подкласс Scene Graph-интерактивного компонента.
item_interactable_component := class(interactable_component):

    # Храним подписку, чтобы корректно отписаться при удалении из сцены.
    var SucceededEventHandler : ?cancelable = false

    OnAddedToScene<override>():void =
        if (not SucceededEventHandler?):
            set SucceededEventHandler = option{ SucceededEvent.Subscribe(OnSucceededEvent) }

    OnRemovingFromScene<override>():void =
        if (Handler := SucceededEventHandler?):
            Handler.Cancel()
            set SucceededEventHandler = false

    # Срабатывает, когда игрок успешно завершил взаимодействие.
    OnSucceededEvent(Agent : agent):void =
        if (PickupInventory := GetInventoryRoot[Agent]):
            # AddItemDistribute проходит по подынвентарям и кладёт в подходящий.
            # GetSuccess[] успешен только если предмет реально приняли.
            if (PickupInventory.AddItemDistribute(Entity).GetSuccess[]):
                Print("Монета подобрана")
                # тут можно убрать мировой пикап / проиграть VFX

    # Текст подсказки взаимодействия — берём имя из метаданных предмета.
    InteractMessage<override>(Agent : agent)<reads><decides>:message =
        if (Details := Entity.GetComponent[coin_item_component]):
            DefaultInteractionMessage      # у coin нет Name; показываем дефолт
        else:
            DefaultInteractionMessage
