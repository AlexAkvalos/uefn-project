using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Собственный канал логирования.
# Каналы позволяют включать/выключать и фильтровать вывод по группам,
# в отличие от «голого» Print().
#
# Использование внутри устройства:
#
#   using { /Verse.org/Simulation }
#   using { /UnrealEngine.com/Temporary/Diagnostics }
#
#   my_device := class(creative_device):
#       Logger : log = log{Channel := project_log}
#
#       OnBegin<override>()<suspends>:void=
#           Logger.Print("Устройство запущено")
#
# project_log — имя канала; его видно в логах UEFN рядом с сообщением.
project_log := class(log_channel){}
