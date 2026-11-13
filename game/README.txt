miron1126 TechShop v2.0.0 «Перезагрузка» — игра про ремонт компьютеров (Godot 4)

ЧТО ЕСТЬ В ВЕРСИИ 2.0.0
- Эпохи 1995–2026: железо, системы, игры и вирусы своего времени
- Нарисованный ПК в разрезе и монитор, детали перетаскиваются в корпус
- Мини-игры: процессор, термопаста, память, пыль, кабели, ловля вирусов
- Rufus, BIOS/UEFI, установка Windows/Linux, ключи, активация
- «Сесть за ПК»: диспетчер задач, проводник, командная строка, браузер, почта
- Бизнес: комната → гараж → магазин → офис → небоскрёб, верстаки, работники
- Город Техноград: вызовы на дом, транспорт
- Компьютерный клуб: места, хит эпохи, бар, консоли, VR, турниры
- Кошка Буся с подсказками

КАК ЗАПУСТИТЬ
1. Скачай Godot 4 (обычную версию, НЕ .NET) с https://godotengine.org/download
   Это просто .exe, устанавливать не надо — распакуй и запусти.
2. В окне Project Manager нажми Import -> выбери файл project.godot из этой папки.
3. Нажми F5 (или кнопку ▶ вверху справа) — игра запустится.

КАК СОБРАТЬ .EXE ДЛЯ WINDOWS
1. Editor -> Manage Export Templates -> Download and Install (один раз).
2. Project -> Export -> Add... -> Windows Desktop.
3. Export Project -> выбери папку -> получишь TechShop.exe (+ .pck рядом).
   Галочка "Embed PCK" — тогда будет один .exe файл.

КАК СОБРАТЬ .APK ДЛЯ ANDROID
1. Поставь Android Studio (нужен Android SDK) и OpenJDK 17.
2. Editor -> Editor Settings -> Export -> Android: укажи пути к SDK и Java.
3. Project -> Install Android Build Template.
4. Project -> Export -> Add... -> Android -> Export Project -> получишь .apk.

ГДЕ ЧТО ЛЕЖИТ
scripts/Data.gd  — все детали, ОС, игры, вирусы, инструменты (добавляй новые сюда)
scripts/Game.gd  — логика: включение ПК, температура, FPS, заказы, сохранения
scripts/Main.gd  — интерфейс (экраны, кнопки)
Сохранение: %APPDATA%\Godot\app_userdata\miron1126 TechShop\techshop_save.json
