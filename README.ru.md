# netverif

Попытка реализовать инструмент верификации с поиском уязвимостей в формальных описаниях сетевых протоколов (например, [CVE-2008-4609](https://nvd.nist.gov/vuln/detail/CVE-2008-4609)).

## Принципы проектирования протоколов надежной передачи данных

1. обнаружение и коррекция ошибок
2. квитирование
3. автоматический запрос повторной передачи данных
4. порядковые номера
5. таймеры отсчета
