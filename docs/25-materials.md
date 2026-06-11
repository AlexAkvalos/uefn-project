# 25. Материалы

Материалы в UEFN — тот же node-граф, что и в полном UE, но с ограничениями. Смена материала из Verse — через `SetMaterial`.

---

## 1. Material Editor и главный узел

Создание: Content Browser → ПКМ → **Material** (или **Material Instance**). Двойной клик → редактор.
Подключаешь узлы-выражения в пины **Main Material Node** → **Apply**/**Save** → назначаешь меш через **Details → Materials**.

**Входы главного узла (Surface):**
- **Base Color** (RGB), **Metallic** (0–1), **Specular** (0.5 по умолч.), **Roughness** (0=зеркало,1=шерохов.),
  **Normal**, **Emissive Color** (>1.0 → HDR/Bloom/свечение), **Opacity** (Translucent), **Opacity Mask** (Masked),
  **Ambient Occlusion**, **World Position Offset** (смещение вершин — ветер/волны).
- Часть входов серая в зависимости от Blend Mode/Shading Model.

## 2. Domain, Blend Mode, Shading Model
- **Material Domain:** Surface (меши), Deferred Decal (декали), **User Interface** (UMG/HUD — см. §7), Post Process.
- **Blend Mode:** **Opaque** (дёшево), **Masked** (бинарный вырез по Opacity Mask — листва/заборы), **Translucent** (мягкая альфа — стекло, дороже).
- **Shading Model:** **Default Lit** (PBR), **Unlit** (только Emissive — UI/голограммы/FX). Остальные (Subsurface…) — наличие зависит от версии.
- **Two Sided** — рендер обеих сторон (полые меши).

## 3. Узлы (доступные в UEFN)
**Texture Sample**, **Constant/Constant3Vector/Constant4Vector**, **Scalar/Vector(Color) Parameter** (только параметры доступны инстансам и Verse!),
**TexCoord**, **Panner** (скролл UV по Time), **Time**, **Multiply/Add**, **Lerp**, **Mask/AppendVector**, **Clamp/Step**, **Noise**, **Fresnel** (рим-эффект), **Material Functions**.

## 4. Material Instances
- Создание: ПКМ по материалу → **Create Material Instance** (`M_..._Inst`).
- Редактируемы **только Parameter-узлы** (ПКМ по константе → **Convert to Parameter**). Включаешь галочкой → переопределяешь, остальное наследуется.
- Правка **родителя** = рекомпиляция шейдера для всех инстансов; правка **инстанса** — дёшево (без рекомпиляции). Делай вариации инстансами.
- **Material Instance Dynamic:** в рантайме меняются **Texture / Scalar / Vector** параметры — автоматически применяются на всех пропах с этим материалом.

## 5. Из Verse — `creative_prop.SetMaterial`
Да, материал и **экспонированные** параметры меняются из Verse (как с Niagara — только то, что вынес в параметры; ассет через **Asset Reflection**).

```verse
SetMaterial(Material : material, ?ElementIndex : int = 0)   # по умолчанию слот 0
```
```verse
# Материал-инстанс, экспонированный через Asset Reflection (папка "Counter"):
MyMat : Counter.AirVent_mat_Inst1_material = Counter.AirVent_mat_Inst1_material{}
MyProp.SetMaterial(MyMat)                    # сменить материал пропа
MyProp.SetMaterial(MyMat, ?ElementIndex := 2)# в слот 2
```
Паттерн: поставить инстанс на проп один раз, затем гонять его **Scalar/Vector/Texture** параметры из геймплея (цвет/яркость/текстура анимируются).

⚠️ **Гочи:** `SetMaterial` работает по Static Mesh Component; на части пропов нужен включённый **Allow Custom Material**.
Сообщения о багах (зависят от версии): поломка Verse-инстансов после v33/v34, материал не обновляется визуально пока игрок не подойдёт (телепортированные пропы), Physical Material из Verse не применяется. Сверяй в своей сборке.

## 6. Текстуры и кастомный workflow
- Импорт: drag в Content Browser. **Размеры — степени двойки** (1024/2048/4096) — нужно для GPU-сжатия.
- **Compression Settings:** **TC_Default** (цвет), **TC_NormalMap** (нормали). sRGB вкл для цвета, выкл для масок/нормалей. 4K@Default ≈ 8 МБ.
- **v39.30:** новый **UI-материал для gauge/спидометров** + Verse vehicle-data API (speed/boost) → кастомные HUD транспорта; обновлён UI Features Example.

## 7. Спец-материалы
- **UI (HUD/UMG):** Domain = **User Interface**. Готовые в **Fortnite → UI → Materials** (M_ProgressBar_Basic/Orb, M_DropShadow, M_IconWithBackground, M_Wave…). Создаёшь инстанс (`M_UGC_[Name]_Inst`), включаешь параметры (Fill, Stroke, Colors, State hover/focus/press). Используют **SDF-текстуры**. Привязка к данным — View Bindings + Verse.
- **Декали:** Domain = Deferred Decal, Blend = Translucent.
- **Post-process материалы:** Domain = Post Process (через Post Process Volume/камеру).
- **Анимированные:** **Panner + Time** (скролл UV), **WPO + Time** (ветер/волны).
- **Emissive/свечение:** Emissive Color **>1.0** → Bloom; умножь на Scalar Parameter → Verse-управляемая яркость; **Fresnel → Emissive** = рим-свечение.

**Простые графы:**
- *Свечение:* `Constant3Vector(цвет) × ScalarParameter "GlowIntensity" → Emissive Color` (Unlit для чистого свечения).
- *Скролл-текстура:* `TexCoord → Panner(Time) → Texture Sample → Base Color/Emissive`.

## 8. Ограничения UEFN vs UE
- ⚠️ **Нет Custom (HLSL) узла** — пишешь логику стоковыми узлами/Material Functions.
- Палитра узлов **урезана** — сверяй в Palette.
- **Бюджет инструкций:** не более ~**500 инструкций** на материал (панель **Stats**; viewmode Shader Complexity).
- Память текстур: степени двойки + TC_Default/NormalMap; high-res только вблизи; **Optimize Textures** инструмент.
- Регрессии валидации динамических параметров (v33–v34) — тестируй перед релизом.

---

## Источники
- Materials in UEFN: https://dev.epicgames.com/documentation/en-us/fortnite/materials-in-unreal-editor-for-fortnite
- Material Nodes and Settings: https://dev.epicgames.com/documentation/en-us/uefn/material-nodes-and-settings-in-unreal-editor-for-fortnite
- Material Library: https://dev.epicgames.com/documentation/en-us/fortnite/material-library-in-unreal-editor-for-fortnite
- Custom UI with Material Instances: https://dev.epicgames.com/documentation/fortnite/creating-custom-ui-with-material-instances-in-unreal-editor-for-fortnite
- Asset Reflection: https://dev.epicgames.com/documentation/en-us/fortnite/exposing-assets-with-asset-reflection-to-verse-in-unreal-editor-for-fortnite
- creative_prop (SetMaterial): https://dev.epicgames.com/documentation/en-us/fortnite/verse-api/fortnitedotcom/devices/creative_prop
- Textures Best Practices: https://dev.epicgames.com/documentation/fortnite/textures-best-practices-in-fortnite

> ⚠️ Наличие Fresnel/части shading-моделей/доменов и поведение `SetMaterial` зависят от версии — сверяй в Palette и на live API.
