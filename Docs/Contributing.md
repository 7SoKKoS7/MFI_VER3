# Правила разработки MFI_VER3

## Основные принципы

### 1. Строгое соблюдение MQL5
- **ТОЛЬКО** файлы .mq5 и .mqh
- Никакого C/C++/Python/скриптов
- Совместимость с MetaTrader 5
- Использование `#property strict`

### 2. Модульная архитектура
- Один механизм = один файл
- Четкое разделение ответственности
- Минимальные зависимости между модулями
- Строгий порядок подключения

### 3. Качество кода
- Работа только с закрытыми барами
- Отсутствие перерисовки (no repaint)
- Оптимизация производительности
- Читаемость и поддерживаемость

## Структура проекта

### Обязательная иерархия
```
MFI_VER3/
├─ README.md
├─ docs/
│  ├─ Architecture.md
│  ├─ MFV_Method_Summary.md
│  ├─ Backtest_Plan.md
│  └─ Contributing.md
├─ DataDocs/
│  └─ datasets.md
├─ data/
│  └─ EURUSD/
│     ├─ EURUSDM1.csv
│     ├─ EURUSDM5.csv
│     ├─ EURUSDM15.csv
│     ├─ EURUSDM30.csv
│     ├─ EURUSDH1.csv
│     ├─ EURUSDH4.csv
│     ├─ EURUSDDaily.csv
│     ├─ EURUSDWeekly.csv
│     └─ EURUSDMonthly.csv
└─ indicator/
   ├─ MFI_Modular.mq5
   └─ include/
      ├─ core/
      │  ├─ Types.mqh
      │  ├─ Config.mqh
      │  ├─ State.mqh
      │  ├─ Utils.mqh
      │  ├─ MarketData.mqh
      │  ├─ ZigZagAdapter.mqh
      │  ├─ PivotEngine.mqh
      │  ├─ TrendEngine.mqh
      │  ├─ Breakout.mqh
      │  ├─ Filters.mqh
      │  ├─ Signals.mqh
      │  ├─ Draw.mqh
      │  ├─ Panel.mqh
      │  └─ Logger.mqh
      ├─ features/
      │  ├─ FastPivot.mqh
      │  ├─ SimpleSwing.mqh
      │  ├─ VolumeFilter.mqh
      │  ├─ SessionFilter.mqh
      │  ├─ ClinchFilter.mqh
      │  ├─ PhaseFilter.mqh
      │  ├─ ImpulseFilter.mqh
      │  └─ Consensus_EMA_RSI.mqh
      └─ adapters/
         ├─ TimeAdapter.mqh
         └─ Safety.mqh
```

## Правила кодирования

### Запрещенные конструкции
```mql5
// НЕ ИСПОЛЬЗОВАТЬ:
auto variable;                    // auto ключевое слово
std::vector<int> data;           // STL контейнеры
std::string text;                // STL строки
template<typename T>             // Шаблоны
try { ... } catch(...) { ... }   // Исключения
new int[10];                     // Динамическое выделение памяти
delete[] ptr;                    // Освобождение памяти
void func(int& param);           // Ссылки в сигнатурах
```

### Обязательные паттерны
```mql5
// ОБЯЗАТЕЛЬНО ИСПОЛЬЗОВАТЬ:
#pragma once                     // В начале каждого .mqh
int idx = IdxOfTF(tf);           // Индексация по ТФ
g_state.trends[idx];             // Доступ через state
input bool UseRussian = true;    // Только в Config.mqh
```

### Стиль кода
```mql5
// Правильное именование
enum MFV_Trend { MFV_Trend_Up, MFV_Trend_Down, MFV_Trend_Flat };
struct MFV_State { /* ... */ };
static MFV_State g_state;

// Правильные комментарии
// Комментарий на русском языке
/* Многострочный комментарий */

// Правильные отступы
if(condition)
{
   statement1;
   statement2;
}
```

## Работа с таймфреймами

### Индексация ТФ
```mql5
// Порядок: M5, M15, H1, H4, D1
int IdxOfTF(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M5:  return 0;
      case PERIOD_M15: return 1;
      case PERIOD_H1:  return 2;
      case PERIOD_H4:  return 3;
      case PERIOD_D1:  return 4;
      default:         return -1;
   }
}
```

### Доступ к данным
```mql5
// Правильно
int idx = IdxOfTF(tf);
g_state.trends[idx] = MFV_Trend_Up;
g_state.pivotHigh[idx] = price;

// Неправильно
g_state.trends[tf] = MFV_Trend_Up;  // Прямое использование ТФ
```

## Порядок подключения модулей

### Строгий порядок в MFI_Modular.mq5
```mql5
#include "include/core/Types.mqh"
#include "include/core/Config.mqh"
#include "include/core/State.mqh"
#include "include/core/Utils.mqh"
#include "include/core/MarketData.mqh"
#include "include/core/ZigZagAdapter.mqh"
#include "include/core/PivotEngine.mqh"
#include "include/core/TrendEngine.mqh"
#include "include/core/Breakout.mqh"
#include "include/core/Filters.mqh"
#include "include/core/Signals.mqh"
#include "include/core/Draw.mqh"
#include "include/core/Panel.mqh"
#include "include/core/Logger.mqh"
```

## Правила работы с данными

### Закрытые бары
```mql5
// Правильно - только закрытые бары
double closePrice = Close[1];  // Цена закрытия предыдущего бара
datetime barTime = Time[1];    // Время предыдущего бара

// Неправильно - текущий бар
double currentPrice = Close[0];  // Может измениться
```

### No Repaint политика
```mql5
// Все решения принимаются на закрытых барах
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   // Проверяем, что у нас есть закрытые бары
   if(rates_total < 2) return 0;
   
   // Работаем только с закрытыми барами
   int currentBar = rates_total - 1;
   if(currentBar < 1) return 0;
   
   // Логика индикатора
   return rates_total;
}
```

## Тестирование

### Обязательные проверки
1. **Компиляция без ошибок и предупреждений**
2. **Отсутствие перерисовки**
3. **Работа на всех ТФ (M5, M15, H1, H4, D1)**
4. **Совместимость с MT5**

### Процедура тестирования
1. Скомпилировать индикатор
2. Добавить на график
3. Проверить работу на разных ТФ
4. Убедиться в отсутствии перерисовки
5. Проверить информационную панель

## Документация

### Обязательная документация
- **README.md** - описание проекта
- **Architecture.md** - архитектура системы
- **MFV_Method_Summary.md** - описание методики
- **Backtest_Plan.md** - план тестирования
- **Contributing.md** - правила разработки

### Комментарии в коде
```mql5
// Обязательные комментарии
// - Описание функции
// - Параметры и возвращаемые значения
// - Особенности реализации
// - Важные замечания

/*
 * Функция: CalculatePivot
 * Описание: Рассчитывает MF-pivot уровни
 * Параметры: tf - таймфрейм, shift - смещение
 * Возвращает: true если расчет успешен
 * Примечание: Работает только с закрытыми барами
 */
bool CalculatePivot(ENUM_TIMEFRAMES tf, int shift)
{
   // Реализация
}
```

## Процесс разработки

### 1. Создание ветки
- Создать отдельную ветку для каждой задачи
- Использовать понятные имена веток
- Связать с issue/задачей

### 2. Разработка
- Следовать правилам кодирования
- Писать тесты для новой функциональности
- Обновлять документацию

### 3. Код-ревью
- Проверить соответствие правилам
- Убедиться в отсутствии перерисовки
- Проверить производительность

### 4. Слияние
- Успешное прохождение тестов
- Одобрение код-ревью
- Обновление документации

## Контакты и поддержка

### Вопросы и предложения
- Создавать Issues в репозитории
- Описывать проблему подробно
- Прикладывать примеры кода

### Участие в разработке
- Fork репозитория
- Создание Pull Request
- Следование правилам разработки

### Лицензия
- Проект основан на стратегии MasterForex-V
- Предназначен для образовательных целей
- Соблюдение авторских прав
