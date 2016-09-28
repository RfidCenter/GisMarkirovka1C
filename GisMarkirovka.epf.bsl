&НаКлиенте
Перем ШинаРфид;
&НаКлиенте
Перем СчитанныеМетки;

&НаКлиенте
Процедура ПриОткрытии(Команда)
    ПодключитьВнешнююКомпоненту("AddIn.RfidBus1cClient");
    ШинаРфид = Новый COMОбъект("AddIn.RfidBus1cClient");
    ШинаРфид.AllowReconnect = True;
    ПодключитьсяКШинеРфид();
    СчитанныеМетки = Новый Массив();
    Gtin = "1234567891234";
    
КонецПроцедуры

&НаКлиенте
Процедура ПодключитьсяКШинеРфид()
    Попытка
        Если ШинаРфид.Connect("demo.rfidbus.rfidcenter.ru", 80, "demo", "demo") Тогда
        //Если ШинаРфид.Connect("127.1", 7266, "demo", "demo") Тогда
            ЭтаФорма.Элементы.СчитывателиПоле.Доступность = Истина;

            ШинаРфид.SubscribeToBusEventReaderStateChanged();
            ШинаРфид.SubscribeToBusEventReaderStateChanged();
            ШинаРфид.SubscribeToBusEventReaderDisconnected();
            ШинаРфид.SubscribeToBusEventReaderReconnected();
            ШинаРфид.SubscribeToBusEventReaderRemoved();
            ШинаРфид.SubscribeToBusEventReaderAdded();
            
            ЭтаФорма.Элементы.СчитатьМеткиКнопка.Доступность = Истина;
            
            ОбновитьСписокСчитывателей();
            
        КонецЕсли;
    Исключение
        Сообщить(ОписаниеОшибки());
        ПодключитьОбработчикОжидания("ПодключитьсяКШинеРфид", 1, Истина);
    КонецПопытки;
КонецПроцедуры

&НаКлиенте
Процедура ОбновитьСписокСчитывателей()
    ЭтаФорма.Элементы.СчитывателиПоле.СписокВыбора.Очистить();
    Для каждого Считыватель Из ШинаРфид.GetReaders() Цикл
        Если Считыватель.IsOpen И Считыватель.IsActive Тогда
            ЭтаФорма.Элементы.СчитывателиПоле.СписокВыбора.Добавить(Считыватель.Id, Считыватель.Name);
            ИдентификаторСчитывателя = Считыватель.Id;
        КонецЕсли;
    КонецЦикла;
    
КонецПроцедуры

&НаКлиенте
Функция ПроверитьСоединение()
    Если ШинаРфид = Null Или Не ШинаРфид.IsConnected Тогда
        ЭтаФорма.Элементы.СчитатьМеткиКнопка.Доступность = Ложь;
        ЭтаФорма.Элементы.ИндивидуализироватьКнопка.Доступность = Ложь;
        Сообщить("Связь с Шиной RFID была потеряна. Переподключение...");
        ШинаРфид.Close();
        ПодключитьсяКШинеРфид();
        Возврат Ложь;
    КонецЕсли;
    Возврат Истина;
КонецФункции

&НаКлиенте
Функция ПолучитьСчитыватель()
    Для каждого Считыватель Из ШинаРфид.GetReaders() Цикл
        Если Считыватель.Id = ИдентификаторСчитывателя И Считыватель.IsActive Тогда
            Возврат Считыватель;
        КонецЕсли;
    КонецЦикла;
    ВызватьИсключение("Выбранный считыватель недоступен")
КонецФункции

&НаКлиенте
Процедура ОчиститьНайденныеМетки(Команда)
    Кизы.Очистить();
    ЭтаФорма.Элементы.ИндивидуализироватьКнопка.Доступность = Ложь;
    ЭтаФорма.Элементы.ВыгрузитьКнопка.Доступность = Ложь;
КонецПроцедуры

&НаКлиенте
Процедура НайтиМетки(Команда)
    НайтиМеткиНаВыбранномСчитывателе();
    Если Кизы.Количество() > 0 Тогда
        ЭтаФорма.Элементы.ИндивидуализироватьКнопка.Доступность = Истина;
        ЭтаФорма.Элементы.ВыгрузитьКнопка.Доступность = Истина;
    КонецЕсли;

КонецПроцедуры


&НаКлиенте
Процедура НайтиМеткиНаВыбранномСчитывателе()
    Если Не ПроверитьСоединение() Тогда
        Возврат;
    КонецЕсли;
        
    Считыватель = ПолучитьСчитыватель();
    ШинаРфид.EnableDecodeEpc(Считыватель.Id);
        
    TransponderBank_Reserved   = 0;
    TransponderBank_Epc        = 1;
    TransponderBank_Tid        = 2;
    TransponderBank_UserMemory = 3;
    
    ЗАГОЛОВОК_SGTIN96 = 48;
    
    Считыватель = ПолучитьСчитыватель();
    Метки = ШинаРфид.GetTransponders(Считыватель.Id);
    
    Для Каждого Метка Из Метки Цикл
        Запись = Кизы.Добавить();
        Запись.Идентификатор = Метка.IdAsString;
        Запись.Статус = "Не индивидуализирована";
        
        ПарольДоступа = Новый Массив(4);
        ПарольДоступа[0] = 0;
        ПарольДоступа[1] = 0;
        ПарольДоступа[2] = 0;
        ПарольДоступа[3] = 0;
        
        Тид = ШинаРфид.ReadMultipleBlocks(Считыватель.Id, Метка, TransponderBank_Tid, 0, 4, ПарольДоступа).Выгрузить();
        Запись.Тид = ByteArrayToHexString(Тид);
        
        СохранитьМетку(Метка, Тид);
        
        РасширенныеДанные = Метка.Extended.Groups.Выгрузить();
        Для Каждого Данные Из РасширенныеДанные Цикл
            Если Данные.Name = "Epc" Тогда
                МассивЕпс = Данные.Items.Выгрузить();
                Если Цел(ПолучитьЗначение(МассивЕпс, "Type")) = ЗАГОЛОВОК_SGTIN96 Тогда
                    Фильтр          = ПолучитьЗначение(МассивЕпс, "Filter");
                    ПрефиксКомпании = ПолучитьЗначение(МассивЕпс, "Gcp");
                    Артикул         = ПолучитьЗначение(МассивЕпс, "Item");
                    СерийныйНомер   = ПолучитьЗначение(МассивЕпс, "Serial");
                    
                    Запись.Sgtin96  = Фильтр + "." + ПрефиксКомпании + "." + Артикул + "." + СерийныйНомер;

                    Если ПрефиксКомпании = Сред(Строка(Gtin), 1, 9) Тогда
                        Запись.Статус = "Индивидуализирована";
                    КонецЕсли;
                КонецЕсли;
            КонецЕсли;
        КонецЦикла;
        
        Итератор = Кизы.Количество() - 2;
        Пока Итератор >= 0 Цикл
            If Кизы.Получить(Итератор).Тид = Запись.Тид Тогда
                Кизы.Удалить(Итератор);
            КонецЕсли;
            
            Итератор = Итератор - 1;
        КонецЦикла;
        
        Кизы.Сортировать("Тид");
        ЭтаФорма.Элементы.ТаблицаНайденныхМеток.Обновить();
    КонецЦикла;
КонецПроцедуры
    
&НаКлиенте
Процедура ИндивидуализироватьМетки(Команда)
    Если Не ПроверитьСоединение() Тогда
        Возврат;
    КонецЕсли;
    
    Считыватель = ПолучитьСчитыватель();
    Для Каждого Индекс Из ЭтаФорма.Элементы.ТаблицаНайденныхМеток.ВыделенныеСтроки Цикл
        Киз = ЭтаФорма.Элементы.ТаблицаНайденныхМеток.ДанныеСтроки(Индекс);
        
        МеткаСТид = ПолучитьМетку(Киз.Тид);
        ТидБайтМассив = МеткаСТид.ТидБайтМассив;
        ДлинаСерийногоНомераТид = ПолучитьДлинуСерийногоНомераТид(ТидБайтМассив);
        ПервыйБайтСерийногоНомераТид = 6;
        СерийныйНомер = 0;
        Для Итератор = 0 По ДлинаСерийногоНомераТид - 1 Цикл
            СерийныйНомер = СерийныйНомер + СдвигВлево(ТидБайтМассив[ДлинаСерийногоНомераТид - Итератор - 1 + ПервыйБайтСерийногоНомераТид], 
                    (ДлинаСерийногоНомераТид - Итератор - 1) * 8);
        КонецЦикла;
        
        НоваяМетка = ШинаРфид.WriteEpcSgtin96(Считыватель.Id, МеткаСТид.Метка, 
                    Цел(Сред(Строка(Gtin), 1, 9)),                           // GCP
                    Цел(Сред(Строка(Gtin), 10, СтрДлина(Строка(Gtin)) - 9)), // Артикул
                    СерийныйНомер,                                           // Серийный номер
                    1,                                                       // Filter Values for SGTIN EPC Tags: 1 - Point of Sale (POS) Trade Item
                    3                                                        // SGTIN Partition Table
        );                                                         
                
        Если БлокироватьМеткуПослеЗаписи Тогда
                                  Сообщить("БЛОК!");
            ПарольДоступа = Новый Массив(4);
            ПарольДоступа[0] = 0;
            ПарольДоступа[1] = 0;
            ПарольДоступа[2] = 0;
            ПарольДоступа[3] = 0;
            
            НовыйПароль = Новый Массив(4);
            НовыйПароль[0] = 11;
            НовыйПароль[1] = 22;
            НовыйПароль[2] = 33;
            НовыйПароль[3] = 44;

            TransponderBankLockType_Unlocked          = 0;
            TransponderBankLockType_PermanentUnlocked = 1;
            TransponderBankLockType_Locked            = 2;
            TransponderBankLockType_PermanentLocked   = 3;
            
            ШинаРфид.SetAccessPassword(Считыватель.Id, НоваяМетка, НовыйПароль, ПарольДоступа);
            ШинаРфид.LockTransponder(Считыватель.Id, НоваяМетка, TransponderBankLockType_PermanentLocked, НовыйПароль);
                    
        КонецЕсли;
    КонецЦикла;
    
    ПодключитьОбработчикОжидания("НайтиМеткиНаВыбранномСчитывателе", 1, Истина);
КонецПроцедуры

&НаКлиенте
Процедура ВыгрузитьXml(Команда)
    
    ЗаписьXml = Новый ЗаписьXML;
    
    Режим = РежимДиалогаВыбораФайла.Сохранение; 
    Диалог = Новый ДиалогВыбораФайла(Режим);
    Диалог.Фильтр = "XML файл (*.xml)|*.xml";

    Если Диалог.Выбрать() Тогда
         ЗаписьXml.ОткрытьФайл(Диалог.ВыбранныеФайлы[0], "UTF-8");
    Иначе
        Возврат;
    КонецЕсли;
    
    ЗаписьXml.ЗаписатьОбъявлениеXML();
    
    ЗаписьXml.ЗаписатьНачалоЭлемента("query");
    ЗаписьXml.ЗаписатьАтрибут("version","2.32");
    ЗаписьXml.ЗаписатьАтрибут("xsi:noNamespaceSchemaLocation","..\xsd_new1\query.xsd");
    
        ЗаписьXml.ЗаписатьНачалоЭлемента("unify_self_signs");
        ЗаписьXml.ЗаписатьАтрибут("action_id","20");
        
            ЗаписьXml.ЗаписатьНачалоЭлемента("sender_gln");
            ЗаписьXml.ЗаписатьТекст(Gln);
            ЗаписьXml.ЗаписатьКонецЭлемента();
            
            ЗаписьXml.ЗаписатьНачалоЭлемента("unify_date");
            ЗаписьXml.ЗаписатьТекст(Формат(
                    УниверсальноеВремя(ТекущаяДата()),
                    "ДФ=""гггг-ММ-ддTЧЧ:мм:ссZ""")
                    );
            ЗаписьXml.ЗаписатьКонецЭлемента();
            
            ЗаписьXml.ЗаписатьНачалоЭлемента("unifies");
            
            Для Каждого Индекс Из ЭтаФорма.Элементы.ТаблицаНайденныхМеток.ВыделенныеСтроки Цикл
                
                Киз = ЭтаФорма.Элементы.ТаблицаНайденныхМеток.ДанныеСтроки(Индекс);

                МеткаСТид = ПолучитьМетку(Киз.Тид);
                Гтин = "";
                Тид = МеткаСТид.ТидСтрока;
                Сгтин = ПереводСтрокиИз16В2Сс(МеткаСТид.Метка.IdAsString);
                
                // Отвязываемся от GUI: берём данные о GTIN из метки
                РасширенныеДанные = МеткаСТид.Метка.Extended.Groups.Выгрузить();
                ЗАГОЛОВОК_SGTIN96 = 48;
                Для Каждого Данные Из РасширенныеДанные Цикл
                    Если Данные.Name = "Epc" Тогда
                        МассивЕпс = Данные.Items.Выгрузить();
                        Если Цел(ПолучитьЗначение(МассивЕпс, "Type")) = ЗАГОЛОВОК_SGTIN96 Тогда
                            Фильтр          = Число(ПолучитьЗначение(МассивЕпс, "Filter"));
                            ПрефиксКомпании = Число(ПолучитьЗначение(МассивЕпс, "Gcp"));
                            Артикул         = Число(ПолучитьЗначение(МассивЕпс, "Item"));
                            СерийныйНомер   = Число(ПолучитьЗначение(МассивЕпс, "Serial"));
                            
                            Гтин = Формат(ПрефиксКомпании, "ЧЦ=9; ЧВН=1; ЧГ=0") 
                                    + Формат(Артикул, "ЧЦ=4; ЧВН=1; ЧГ=0");
                                    
                        КонецЕсли;
                    КонецЕсли;
                КонецЦикла;
                
                ЗаписьXml.ЗаписатьНачалоЭлемента("by_gtin");
                    ЗаписьXml.ЗаписатьНачалоЭлемента("sign_gtin");
                    ЗаписьXml.ЗаписатьТекст(Гтин);
                    ЗаписьXml.ЗаписатьКонецЭлемента();
                    
                    ЗаписьXml.ЗаписатьНачалоЭлемента("union");
                        ЗаписьXml.ЗаписатьНачалоЭлемента("gs1_sgtin");
                        ЗаписьXml.ЗаписатьТекст(Сгтин);
                        ЗаписьXml.ЗаписатьКонецЭлемента();
                        
                        ЗаписьXml.ЗаписатьНачалоЭлемента("TID");
                        ЗаписьXml.ЗаписатьТекст(Тид);
                        ЗаписьXml.ЗаписатьКонецЭлемента();
                    ЗаписьXml.ЗаписатьКонецЭлемента(); // union
                ЗаписьXml.ЗаписатьКонецЭлемента(); // by_gtin
            КонецЦикла;
                
            ЗаписьXml.ЗаписатьКонецЭлемента(); // unifies
     
        ЗаписьXml.ЗаписатьКонецЭлемента(); // unify_self_signs
    ЗаписьXml.ЗаписатьКонецЭлемента(); // query
    ЗаписьXml.Закрыть();
КонецПроцедуры

&НаКлиенте
Функция ПолучитьДлинуСерийногоНомераТид(ТидБайтМассив)
    // 16.2.2. XTID Serialization
    // http://www.gs1.org/sites/default/files/docs/epc/TDS_1_9_Standard.pdf
    
    БитыДлины = СдвигВправо(ТидБайтМассив[4], 5);
    
    Значение = 0;
    Если БитыДлины = 1 Тогда
        Значение = 4;
    ИначеЕсли БитыДлины = 2  Тогда
        Значение = 2;
    ИначеЕсли БитыДлины = 3 Тогда
        Значение = 6;
    ИначеЕсли БитыДлины = 4 Тогда
        Значение = 1;
    ИначеЕсли БитыДлины = 5 Тогда
        Значение = 5;
    ИначеЕсли БитыДлины = 6 Тогда
        Значение = 3;
    ИначеЕсли БитыДлины = 7 Тогда
        Значение = -1;
    Иначе
        Возврат 0;
    КонецЕсли;
        
    Возврат (48 + ((Значение - 1) * 16)) / 8;
    
КонецФункции    

&НаКлиенте
Процедура СохранитьМетку(НоваяМетка, ТидБайтМассив)
    
    ТидСтрока = ByteArrayToHexString(ТидБайтМассив);
    
    Итератор = СчитанныеМетки.Количество() - 1;
    Пока Итератор >= 0 Цикл
        If СчитанныеМетки[Итератор].ТидСтрока = ТидСтрока Тогда
            СчитанныеМетки.Удалить(Итератор);
        КонецЕсли;
        Итератор = Итератор - 1;
    КонецЦикла;
    
    МеткаСТид = Новый Структура;
    МеткаСТид.Вставить("Метка", НоваяМетка);
    МеткаСТид.Вставить("ТидБайтМассив",  ТидБайтМассив);
    МеткаСТид.Вставить("ТидСтрока", ТидСтрока);
    
    СчитанныеМетки.Добавить(МеткаСТид);
    
КонецПроцедуры

&НаКлиенте
Функция ПолучитьМетку(ТидСтрока)
    Для Каждого Метка Из СчитанныеМетки Цикл
        Если Метка.ТидСтрока = ТидСтрока Тогда
            Возврат Метка;
        КонецЕсли;
    КонецЦикла;
КонецФункции

&НаКлиенте
Процедура ОбработчикСобытий(Источник, Событие, Данные)
    Если Источник = "RfidBus1cClient" Тогда
        ДеталиСобытия = ШинаРфид.GetEventDetails(Данные);
         
        Если Событие = "BusEventReaderStateChanged" 
                Или Событие = "BusEventReaderRemoved" 
                Или Событие = "BusEventReaderReconnected" 
                Или Событие = "BusEventReaderAdded"
        Тогда
            ОбновитьСписокСчитывателей();
        КонецЕсли;
        
        Если Событие = "Disconnected" Тогда
            Сообщить("Разорвана связь с Шиной РФИД. Переподключение...");
            
            ЭтаФорма.Элементы.СчитывателиПоле.Доступность = Ложь;
            ЭтаФорма.Элементы.СчитатьМеткиКнопка.Доступность = Ложь;
            ЭтаФорма.Элементы.ИндивидуализироватьКнопка.Доступность = Ложь;
            ЭтаФорма.Элементы.ВыгрузитьКнопка.Доступность = Ложь;
            
            ПодключитьОбработчикОжидания("ПодключитьсяКШинеРфид", 1, Истина);
        КонецЕсли;
        
        Если Событие = "Reconnected" Тогда
            ЭтаФорма.Элементы.СчитывателиПоле.Доступность = Истина;
            Сообщить("Реконнектед!");
        КонецЕсли;

        
    КонецЕсли;
        
КонецПроцедуры

&НаКлиенте
Функция СдвигВправо(Знач Число, Сдвиг)
    Для Итератор = 1 По Сдвиг Цикл
        Число = Цел(Число / 2);
    КонецЦикла;
    Возврат Число;
КонецФункции

&НаКлиенте
Функция СдвигВлево(Знач Число, Сдвиг)
    Для Итератор = 1 По Сдвиг Цикл
        Число = Цел(Число * 2);
    КонецЦикла;
    Возврат Число;
КонецФункции

&НаКлиенте
Функция ПолучитьЗначение(Массив, ИмяПоля)
    Для Каждого Элемент Из Массив Цикл
        Если Элемент.Name = ИмяПоля Тогда
            Возврат Элемент.Value;
        КонецЕсли;
    КонецЦикла;
    Возврат NULL;
КонецФункции

&AtClient
Function ByteArrayToHexString(array, delimiter=0)
    result = "";
    len = 0;
    
    For each byte In array Do
        hByte = DecToAny(byte, 16);
        
        If StrLen(hByte) < 2 Then
            hByte = "0" + hByte;
        EndIf;
        
        If delimiter > 0 And len > 0 And len%delimiter = 0 Then
            result = result + " ";
        EndIf;
        
        result = result + hByte;
        len = len + 1;
    EndDo;
    
    Return result;
EndFunction

&AtClient
Function DecToAny(Val number, base)
    result = "";

    If number = 0 Then
        Return "0";
    EndIf;

    While number > 0 Do
        result = Mid("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", number % base  +  1, 1) + result;
        number = Int(number / base) ;
    EndDo;
    
    Return result;
EndFunction

&НаКлиенте
Функция ПереводСтрокиИз16В2Сс(СтрокаВСс16)
    Результат = "";
    Для Итератор = 1 По СтрДлина(СтрокаВСс16) Цикл
        Символ = Сред(СтрокаВСс16, Итератор, 1);
        Если Символ = "0" Тогда
            Результат = Результат + "0000";
        ИначеЕсли Символ = "1" Тогда
            Результат = Результат + "0001";
        ИначеЕсли Символ = "2" Тогда
            Результат = Результат + "0010";
        ИначеЕсли Символ = "3" Тогда
            Результат = Результат + "0011";
        ИначеЕсли Символ = "4" Тогда
            Результат = Результат + "0100";
        ИначеЕсли Символ = "5" Тогда
            Результат = Результат + "0101";
        ИначеЕсли Символ = "6" Тогда
            Результат = Результат + "0110";
        ИначеЕсли Символ = "7" Тогда
            Результат = Результат + "0111";
        ИначеЕсли Символ = "8" Тогда
            Результат = Результат + "1000";
        ИначеЕсли Символ = "9" Тогда
            Результат = Результат + "1001";
        ИначеЕсли Символ = "A" Тогда
            Результат = Результат + "1010";
        ИначеЕсли Символ = "B" Тогда
            Результат = Результат + "1011";
        ИначеЕсли Символ = "C" Тогда
            Результат = Результат + "1100";
        ИначеЕсли Символ = "D" Тогда
            Результат = Результат + "1101";
        ИначеЕсли Символ = "E" Тогда
            Результат = Результат + "1110";
        ИначеЕсли Символ = "F" Тогда
            Результат = Результат + "1111";
        КонецЕсли;
    КонецЦикла;

    Возврат Результат;
КонецФункции
