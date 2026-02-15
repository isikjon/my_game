# Taxi App - Flutter Mobile Application

Мобильное приложение для такси на Flutter с интеграцией FastAPI backend.

## Структура проекта

```
lib/
├── config/          # Конфигурация приложения
├── models/          # Модели данных
├── screens/         # Экраны приложения
├── services/        # Сервисы для работы с API
├── styles/          # Глобальные стили и темизация
├── utils/           # Утилиты
├── widgets/         # Переиспользуемые UI-компоненты
└── main.dart        # Точка входа приложения
```

## Зависимости

- dio: HTTP клиент для работы с API
- provider: Управление состоянием
- go_router: Навигация
- shared_preferences: Локальное хранилище
- flutter_svg: Поддержка SVG
- cached_network_image: Кэширование изображений
- intl: Интернационализация

## Запуск

```bash
flutter pub get
flutter run
```

## API Configuration

Настройка API находится в `lib/config/api_config.dart`.
По умолчанию используется `http://localhost:8000/api/v1`.

# my_game
