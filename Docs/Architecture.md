# Архитектура MFI_VER3

## Обзор

MFI_VER3 — это модульная реализация индикатора MasterForex-V для MetaTrader 5. Проект построен на принципах модульности, разделения ответственности и строгого соблюдения правил MQL5.

## Принципы архитектуры

### 1. Модульность
- Каждый модуль отвечает за одну конкретную функцию
- Минимальные зависимости между модулями
- Четкое разделение интерфейсов и реализации

### 2. Строгие ограничения
- **ТОЛЬКО MQL5** (.mq5/.mqh файлы)
- Никакого C/C++/Python/скриптов
- Работа только с закрытыми барами
- Без перерисовки (no repaint)

### 3. Иерархия модулей

```
indicator/
├─ MFI_Modular.mq5          # Главный файл индикатора
└─ include/
   ├─ core/                 # Основные модули
   │  ├─ Types.mqh         # Типы и перечисления
   │  ├─ Config.mqh        # Input параметры
   │  ├─ State.mqh         # Глобальное состояние
   │  ├─ Utils.mqh         # Утилиты
   │  ├─ MarketData.mqh    # Работа с рыночными данными
   │  ├─ ZigZagAdapter.mqh # Адаптер ZigZag
   │  ├─ PivotEngine.mqh   # Движок пивотов
   │  ├─ TrendEngine.mqh   # Движок трендов
   │  ├─ Breakout.mqh      # Логика пробоев
   │  ├─ Filters.mqh       # Основные фильтры
   │  ├─ Signals.mqh       # Генерация сигналов
   │  ├─ Draw.mqh          # Отрисовка графики
   │  ├─ Panel.mqh         # Информационная панель
   │  └─ Logger.mqh        # Логирование
   ├─ features/            # Дополнительные функции
   │  ├─ FastPivot.mqh     # Быстрые пивоты
   │  ├─ SimpleSwing.mqh   # Простые свинги
   │  ├─ VolumeFilter.mqh  # Фильтр объема
   │  ├─ SessionFilter.mqh # Фильтр сессий
   │  ├─ ClinchFilter.mqh  # Фильтр схватки
   │  ├─ PhaseFilter.mqh   # Фильтр фазы
   │  ├─ ImpulseFilter.mqh # Фильтр импульса
   │  └─ Consensus_EMA_RSI.mqh # Консенсус EMA/RSI
   └─ adapters/            # Адаптеры
      ├─ TimeAdapter.mqh   # Адаптер времени
      └─ Safety.mqh        # Безопасность
```

## Порядок подключения модулей

Строгий порядок include в главном файле:
1. Types.mqh
2. Config.mqh  
3. State.mqh
4. Utils.mqh
5. MarketData.mqh
6. ZigZagAdapter.mqh
7. PivotEngine.mqh
8. TrendEngine.mqh
9. Breakout.mqh
10. Filters.mqh
11. Signals.mqh
12. Draw.mqh
13. Panel.mqh
14. Logger.mqh

## Ответственность модулей

### Core модули
- **Types.mqh**: Определение всех перечислений и типов
- **Config.mqh**: Единственный источник input параметров
- **State.mqh**: Глобальное состояние и кеши
- **Utils.mqh**: Общие утилиты и хелперы
- **MarketData.mqh**: Получение цен, ATR, проверка достаточности баров
- **ZigZagAdapter.mqh**: Работа с встроенным ZigZag
- **PivotEngine.mqh**: Расчет MF-pivot уровней
- **TrendEngine.mqh**: Определение трендов и причин
- **Breakout.mqh**: Логика пробоев и ретестов
- **Filters.mqh**: Основные фильтры качества
- **Signals.mqh**: Генерация торговых сигналов
- **Draw.mqh**: Единственный модуль для отрисовки графики
- **Panel.mqh**: Информационная панель (только отображение)
- **Logger.mqh**: Система логирования

### Features модули
- **FastPivot.mqh**: Быстрые пивоты для UI
- **SimpleSwing.mqh**: Простые свинги
- **VolumeFilter.mqh**: Фильтр по объему
- **SessionFilter.mqh**: Фильтр торговых сессий
- **ClinchFilter.mqh**: Фильтр схватки
- **PhaseFilter.mqh**: Фильтр рыночной фазы
- **ImpulseFilter.mqh**: Фильтр импульса/отката
- **Consensus_EMA_RSI.mqh**: Консенсус EMA/RSI

### Adapters модули
- **TimeAdapter.mqh**: Работа с временными зонами
- **Safety.mqh**: Проверки безопасности

## Правила разработки

### 1. Запрещенные конструкции
- `auto` ключевое слово
- STL контейнеры (`std::vector`, `std::string`)
- Лямбда-функции
- Шаблоны (`template`)
- Исключения (`try/catch`)
- Динамическое выделение памяти (`new/delete`)
- Ссылки в сигнатурах функций

### 2. Обязательные паттерны
- `#pragma once` в начале каждого .mqh файла
- Индексация через `IdxOfTF(tf)`
- Использование `state.*[idx]` для доступа к данным
- Единый источник input параметров в Config.mqh

### 3. Работа с таймфреймами
- Строгая изоляция по ТФ
- Никаких фолбэков между ТФ
- Только закрытые бары (shift >= 1)
- Порядок UI: M5 M15 H1 H4 D1

## Глобальные переменные

Единственная разрешенная глобальная переменная:
```mql5
static MFV_State g_state;
```

Все остальные данные должны быть индексированы по ТФ через `IdxOfTF(tf)`.

## Совместимость

- MetaTrader 5
- `#property strict`
- Только закрытые бары
- Без перерисовки
- Совместимость с терминалом MT5
