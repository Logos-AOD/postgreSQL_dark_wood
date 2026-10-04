-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:

-- Проверка на корректность данных по полю payer. Использование значений поля payer напрямую

-- Группировка по 0 и 1 payer. Проверка на корректность данных
SELECT 
	f_us.payer,
	count(f_us.id) AS count_id
FROM fantasy.users AS f_us
GROUP BY 
	f_us.payer
-- Среди payer аномальных значений нет.
	

-- Альтернативный код
-- Строка с All покажет все строки, даже с пропусками (включая NULL)
SELECT
	--CAST(payer AS VARCHAR) AS payer,
    COALESCE(CAST(payer AS VARCHAR), 'All') AS payer, 
    COUNT(*) AS total_users,  
    SUM(payer) AS total_payers,  
    ROUND(AVG(payer),4) AS payers_share
FROM fantasy.users
GROUP BY ROLLUP(payer)
ORDER BY 
    CASE 
	    WHEN payer IS NULL 
	    	THEN 1 
	    	ELSE 0 
		END,
    payer::INT asc;




SELECT 
	-- Общее количество игроков, зарегистрированных в игре
	count(f_us.payer) AS count_id_users,
	-- Количество платящих игроков по все данным
	sum(f_us.payer) AS count_id_users_pay,
	-- Доля платящих игроков от общего количества пользователей, зарегистрированных в игре
	avg(f_us.payer) AS frac_pay_us
FROM fantasy.users AS f_us

--	|	count_id_users	|	count_id_users_pay	|	frac_pay_us		|
----|-------------------|-----------------------|-------------------|
----|		22 214		|		3 929			|		0.1769		|

-- Доля платящих игроков составляет 0.1769.


-- 1.2. Доля платящих пользователей в разрезе расы персонажа:



-- CTE для подсчета общего количества игроков в разрезе расы персонажа
WITH id_count AS (
	SELECT 
		-- Вывод названий рас персонажей
		f_ra.race,
		-- Общее количество игроков, зарегистрированных в игре
		count(f_us.id) AS count_id_users
		-- Количество платящих игроков по все данным
	FROM fantasy.users AS f_us
	INNER JOIN fantasy.race AS f_ra
		ON f_us.race_id = f_ra.race_id
	GROUP BY 
		f_ra.race
),
-- CTE для подсчета количества платящих игроков в разрезе расы персонажа
id_count_pay AS (
	SELECT 
		-- Вывод названий рас персонажей
		f_ra.race,
		-- Общее количество игроков, зарегистрированных в игре
		count(f_us.id) AS count_id_users_pay
		-- Количество платящих игроков по все даннм
	FROM fantasy.users AS f_us
	INNER JOIN fantasy.race AS f_ra
		ON f_us.race_id = f_ra.race_id
	WHERE 
		f_us.payer = 1
	GROUP BY 
		f_ra.race
)
-- Вывод показателей из cte и добавление доли платяших игроков от общего количества по расам
SELECT 
	-- Вывод названий рас персонажей
	id_count.race,
	-- Общее количество игроков, зарегистрированных в игре, по расам
	id_count.count_id_users,
	-- Количество платящих игроков по расам
	id_count_pay.count_id_users_pay,
	-- Доля платящих игроков от общего количества пользователей, зарегистрированных в игре, по расам
	round(count_id_users_pay::numeric / count_id_users, 4) AS frac_pay_us
FROM id_count
-- Присоединем таблицу из CTE по платящим игрокам
INNER JOIN id_count_pay
	ON id_count.race = id_count_pay.race
ORDER BY 
	frac_pay_us DESC;
	
---race 	|	count_id_users	|	count_id_users_pay	|	frac_pay_us		|
------------|-------------------|-----------------------|-------------------|
-- Demon	|		1 229		|		238				|		0.1937		|
-- Hobbit	|		3 648		|		659				|		0.1806		|
-- Human	|		6 328		|		1 114			|		0.1760		|
-- Orc		|		3 619		|		636				|		0.1757		|
-- Northman	|		3 562		|		626				|		0.1757		|
-- Angel	|		1 327		|		229				|		0.1726		|
-- Elf		|		2 501		|		427				|		0.1707		|
-- ТОП-3 рас по общему количеству игроков - Human (6328 игроков), Hobbit (3648 игроков), Orc (3619 Игроков)
-- ТОП-3 рас по количеству платящих игроков - Human (1114 игроков), Hobbit (659 игроков), Orc (636 Игроков)
-- ТОП-3 рас по доли платящих игроков - Demon (19.37% игроков), Hobbit (18.06% игроков), Human (17.60% Игроков)
-- Наиболее типичной расой по платящим игрокам является Human (17.60%). Она же является наиболее популярной расой среди игроков.

-- Чаще всего совершают покупки игроки, которые выбирают в качестве расы своего персонажа - Demon. Но при этом данная раса
-- является наименее популярной среди всех игроков. Раса Demon обладает малой выборкой. Поэтому показатель доли этой расы нельзя применить
-- ко всей выборке по расам. Тогда как лидеры по количеству игроков обладают существенной выборкой и их доли платящих ближе к средней по всем данным.
-- Довести показатель всей выборки до показателя доли платящих у расы Demon может потребовать существенных дополнительных расходов на маркетинговые компании.
-- Выбор расы влияет на долю платящих игроков.


-- Код с итогами для оценки доли каждой расы от общего количества
SELECT
    COALESCE(r.race, 'All') AS race,
    COUNT(*) AS total_users,
    SUM(u.payer) AS total_payers,
    ROUND(SUM(u.payer)::numeric / COUNT(*) * 100, 1) AS share_payers  
FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r USING(race_id)
GROUP BY ROLLUP(r.race)
ORDER BY 
    CASE WHEN r.race IS NULL THEN 1 ELSE 0 END,
    share_payers DESC;






-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:

-- Допольнительный показатель медианы
-- Добавление строки без нулевых покупок
SELECT 
	-- Общее количество покупок
	count(f_ev.transaction_id) AS count_tr,
	-- Суммарная стоимость всех покупок
	sum(f_ev.amount) AS total_amount,
	-- Минимальная стоимость покупки
	min(f_ev.amount) AS min_amount,
	-- Максимальная стоимость покупки
	max(f_ev.amount) AS max_amount,
	-- Среднее значение стоимости покупок
	round(avg(f_ev.amount)::numeric, 2) AS avg_amount,
	-- Медианная стоимость покупок. CONT
	round(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS cont_median_amount,
	-- Медианная стоимость покупок. DISC
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS disc_median_amount,
	-- Стандартное отклонение стоимости покупок
	round(STDDEV(amount)::NUMERIC, 2) AS stand_dev_amount
FROM fantasy.events AS f_ev
UNION
-- Добавление строки без нулевых покупок
SELECT 
	-- Общее количество покупок
	count(f_ev.transaction_id) AS count_tr,
	-- Суммарная стоимость всех покупок
	sum(f_ev.amount) AS total_amount,
	-- Минимальная стоимость покупки
	min(f_ev.amount) AS min_amount,
	-- Максимальная стоимость покупки
	max(f_ev.amount) AS max_amount,
	-- Среднее значение стоимости покупок
	round(avg(f_ev.amount)::numeric, 2) AS avg_amount,
	-- Медианная стоимость покупок. CONT
	round(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS cont_median_amount,
	-- Медианная стоимость покупок. DISC
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS disc_median_amount,
	-- Стандартное отклонение стоимости покупок
	round(STDDEV(amount)::NUMERIC, 2) AS stand_dev_amount
FROM fantasy.events AS f_ev
WHERE 
	f_ev.amount > 0;


--	count_tr	|	total_amount	|	min_amount	|	max_amount	|	avg_amount	|	cont_median_amount	|	disc_median_amount	|	stand_dev_amount	|
----------------|-------------------|---------------|---------------|---------------|-----------------------|-----------------------|-----------------------|
--	1 307 771	|	686 615 040		|		0.01	|	486 615.1	|	526.06		|		74.86			|		74.86			|		2 518.18		|
--	1 307 678	|	686 615 040		|		0		|	486 615.1	|	525.69		|		74.86			|		74.86			|		2 517.35		|

-- Всего внутриигровых покупок - 1.3 млн.
-- Имеется сильная разница между средним (525.69) значением покупки и медианным (74.86). Среднее больше медианы.
-- В выборке много малых значений стоимости покупки и мало крупных, из-за чего среднее значение сильно выше медианы.
-- Показатели медиан совпадают
-- Влияние нулевых покупок на статистические показатели не существенное.
-- Стандартное отклонение гораздо выше среднего. Вероятно имеется большой разброс данных по стоимости покупки.

-- Крупные покупки
SELECT 
	f_ev.item_code,
	f_it.game_items,
	f_co.location,
	f_cl.class,
	sum(f_ev.amount) AS sum_amount,
	count(f_ev.transaction_id) AS count_amount
FROM fantasy.users AS f_us
LEFT JOIN fantasy.events AS f_ev
	ON f_us.id = f_ev.id
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
INNER JOIN fantasy.country AS f_co
	ON f_us.loc_id = f_co.loc_id
INNER JOIN fantasy.classes AS f_cl
	ON f_us.class_id = f_cl.class_id
WHERE
	f_ev.amount > 50000
GROUP BY 
	f_ev.item_code,
	f_it.game_items,
	f_co.location,
	f_cl.class
ORDER BY 
	sum_amount DESC;
-- В выборке покупок стоимостью выше 50 000 по суммарной стоимости и 
-- количеству покупок большинство составляют выходцы из United States. Классы персонажей разнообразны.
-- Покупаемый предмет - 6010 Book of Legends. 
-- Абсолютный лидер: игрок выходец из United States с персонажем Knight, 
-- суммарная стоимость покупок - 14 млн, количеством покупок - 117.




-- 2.2: Аномальные нулевые покупки:

SELECT 
	-- Количество нулевых покупок
	count(*) FILTER (WHERE amount = 0) AS null_amount,
	-- Доля нулевых покупок
	round(count(*) FILTER (WHERE amount = 0)::NUMERIC / count(*), 5) AS frac_null_amount
FROM fantasy.events AS f_ev
	
-- |	null_amount	|	frac_null_amount	|	
---|----------------|-----------------------|
-- |		907		|		0.00069			|
-- Доля нулевых покупок от общего числа покупок составляет 0.00069 (0.069%)

-- Нулевые покупки при платящих игроков
SELECT
	f_it.item_code,
	f_it.game_items,
	-- Количество игроков по условиям с нулевыми покупками и платящие
	count(f_us.id) AS count_id_us,
	count(DISTINCT f_us.id) AS unique_count_id_us
FROM fantasy.users AS f_us
LEFT JOIN fantasy.events AS f_ev
	ON f_us.id = f_ev.id
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
WHERE
	f_ev.amount = 0
	AND f_us.payer = 1
GROUP BY
	f_it.item_code,
	f_it.game_items
-- 835 раз 22 игрока купили самый популярный предмет 6010 Book of Legends за реальные деньги(?)


-- Нулевые покупки по предметам
SELECT 
	f_ev.item_code,
	f_it.game_items,
	count(f_ev.item_code) AS count_anom
FROM fantasy.events AS f_ev
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
WHERE
	amount = 0
GROUP BY 
	f_ev.item_code,
	f_it.game_items
-- Все нулевые покупки - это покупки эпического предмета с кодом 6010 Book of Legends.


-- 2.3: Популярные эпические предметы:
-- Расчет показателей покупок по предметам
SELECT 
	f_ev.item_code,
	f_it.game_items,
	-- Количество покупок по предметам
	count(f_ev.transaction_id) AS count_am,
	-- Доля предметов по общему количеству покупок
	round((count(f_ev.transaction_id)::NUMERIC / sum(count(f_ev.transaction_id)) over()), 4) AS frac_am,--(SELECT count(transaction_id) FROM fantasy.events WHERE amount > 0), 4) AS frac_am,
	-- Сумма покупок по предметам
	sum(f_ev.amount) AS sum_am,
	-- Количество игроков по предметам
	count(DISTINCT f_ev.id) AS count_id_us,
	-- Доля игроков купивших этот предмет от общего числа игроков с покупками
	round(count(DISTINCT f_ev.id)::NUMERIC / (SELECT count(DISTINCT id) FROM fantasy.events WHERE amount > 0), 4) AS frac_id_us
FROM fantasy.events AS f_ev
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
WHERE
	f_ev.amount > 0
GROUP BY 
	f_ev.item_code,
	f_it.game_items
ORDER BY
	count_am DESC,
	sum_am desc;
-- ТОП-2 самых популярных предметов: 6010 Book of Legends - 1 004 516 шт. на сумму 436 921 700, 6011 Bag of Holding - 271 875 шт. на сумму 240 579 800.
-- Самый популярный предмет - 6010 Book of Legends. Его доля от общего количества покупок - 76,87%. Его купили 12 194 игроков. 
-- Что составляет 88,41% от общего числа платящих игроков
-- Второй самый популярный предмет - 6011 Bag of Holdingю Его доля от общего количества покупок - 20,80%. Его купили 11 968 игроков. 
-- Что составляет 86,77% от общего числа платящих игроков.


-- Совокупная статистика по предметам за исключением 2-х самых популярных
SELECT 
	-- Количество покупок за исключением 2-х самых популярных
	count(f_ev.transaction_id) AS count_am,
	-- Доля предметов по общему количеству покупок
	round(count(f_ev.transaction_id)::NUMERIC / (SELECT count(transaction_id) FROM fantasy.events WHERE amount > 0), 4) AS frac_am,
	-- Сумма покупок за исключением 2-х самых популярных
	sum(f_ev.amount) AS sum_am,
	-- Количество игроков за исключением 2-х самых популярных
	count(DISTINCT f_ev.id) AS count_id_us,
	-- Доля игроков купивших этот предмет от общего числа игроков с покупками
	round(count(DISTINCT f_ev.id)::NUMERIC / (SELECT count(DISTINCT id) FROM fantasy.events WHERE amount > 0), 4) AS frac_id_us
FROM fantasy.events AS f_ev
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
WHERE
	f_ev.amount > 0
	AND f_ev.item_code NOT in (6010, 6011)
-- Все остальные предметы купили 30 380 раз на сумму 9,5 млн, что составляет 2,32% от количества всех покупок.
-- Остальные предметы купили 5 609 игроков, что составляет 40,67% от всех игроков с покупками.
	
	
-- Расчет показателей покупок по ТОП-2 предметам и по расам
SELECT 
	f_ra.race,
	-- Количество покупок по предметам
	count(f_ev.transaction_id) AS count_am,
	-- Доля предметов по общему количеству покупок
	round(count(f_ev.transaction_id)::NUMERIC / (SELECT count(transaction_id) FROM fantasy.events WHERE amount > 0), 4) AS frac_am,
	-- Сумма покупок по предметам
	sum(f_ev.amount) AS sum_am,
	-- Количество игроков по предметам
	count(DISTINCT f_ev.id) AS count_id_us,
	-- Доля игроков купивших этот предмет от общего числа игроков с покупками
	round(count(DISTINCT f_ev.id)::NUMERIC / (SELECT count(DISTINCT id) FROM fantasy.events WHERE amount > 0), 4) AS frac_id_us
FROM fantasy.users AS f_us
LEFT JOIN fantasy.events AS f_ev
	ON f_us.id = f_ev.id
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
INNER JOIN fantasy.race AS f_ra
	ON f_us.race_id = f_ra.race_id
WHERE
	f_ev.amount > 0
	AND f_ev.item_code in (6010, 6011)
GROUP BY 
	f_ev.item_code,
	f_it.game_items,
	f_ra.race
HAVING 
	count(f_ev.transaction_id) > 100000
ORDER BY
	count_am DESC,
	sum_am desc;

--	|	race	|	count_am	|	frac_am		|	sum_am		|	count_id_us		|	frac_id_us	|
----|-----------|---------------|---------------|---------------|-------------------|---------------|
--	|	Human	|	389 680		|	0.2982		|	120 117 376	|		3 455		|	0.2505		|
--	|	Hobbit	|	145 211		|	0.1111		|	68 465 696	|		1 993		|	0.1445		|
--	|	Orc		|	138 716		|	0.1062		|	58 800 244	|		2 029		|	0.1471		|
--	|	Northman|	131 433		|	0.1006		|	97 092 272	|		1 956		|	0.1418		|


-- Совокупная статистика по предметам и по расам за исключением 2-х самых популярных
SELECT 
	f_ra.race,
	-- Количество покупок за исключением 2-х самых популярных
	count(f_ev.transaction_id) AS count_am,
	-- Доля предметов по общему количеству покупок
	round(count(f_ev.transaction_id)::NUMERIC / (SELECT count(transaction_id) FROM fantasy.events WHERE amount > 0), 4) AS frac_am,
	-- Сумма покупок за исключением 2-х самых популярных
	sum(f_ev.amount) AS sum_am,
	-- Количество игроков за исключением 2-х самых популярных
	count(DISTINCT f_ev.id) AS count_id_us,
	-- Доля игроков купивших этот предмет от общего числа игроков с покупками
	round(count(DISTINCT f_ev.id)::NUMERIC / (SELECT count(DISTINCT id) FROM fantasy.events WHERE amount > 0), 4) AS frac_id_us
FROM fantasy.users AS f_us
LEFT JOIN fantasy.events AS f_ev
	ON f_us.id = f_ev.id
INNER JOIN fantasy.items AS f_it
	ON f_ev.item_code = f_it.item_code
INNER JOIN fantasy.race AS f_ra
	ON f_us.race_id = f_ra.race_id
WHERE
	f_ev.amount > 0
	AND f_ev.item_code NOT in (6010, 6011)
GROUP BY
	f_ra.race;

--	|	race	|	count_am	|	frac_am		|	sum_am		|	count_id_us		|	frac_id_us	|
----|-----------|---------------|---------------|---------------|-------------------|---------------|
--	|	Human	|	8 177		|	0.0063		|	2 603 583	|		1 606		|	0.1164		|
--	|	Hobbit	|	5 304		|	0.0041		|	1 782 178	|		913			|	0.0662		|
--	|	Northman|	4 745		|	0.0036		|	1 623 433	|		934 		|	0.0677		|
--	|	Orc		|	4 450		|	0.0034		|	1 218 844	|		921 		|	0.0668		|



-- Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:

-- Альтернативный код. Оптимизированный
-- CTE c группированными (а значит уникальным) id - игроки, count(*) - количеству, сумме покупок
WITH events_per_user AS(
        SELECT 
            id,
            COUNT(*) AS event_per_user,
            --
            -- приводим тип данных к ::NUMERIC, т.к. в БД у этой колонки  → amount
            -- тип данных REAL, что приводит к погрешности при расчете суммы покупок и среднего чека
            -- но в этом случае падает скорость обработки, т.к. изменение типа данных довольно затратно
            SUM(amount::NUMERIC) AS total_amount_per_user
            --
        FROM fantasy.events
        WHERE amount > 0
        GROUP BY id
)
SELECT
    race,
    COUNT(id) AS users, -- количество игроков по каждой расе
    COUNT(event_per_user) AS buying_users, -- количество игроков по каждой расе с покупками
    ROUND(COUNT(event_per_user)*100:: NUMERIC/COUNT(id),2) AS buying_users_share, 	-- количество игроков по каждой расе с покупками / 
    																				--количество игроков по каждой расе - доля 
    ROUND(SUM(CASE WHEN payer = 1 AND event_per_user IS NOT NULL THEN 1 END) *100 :: NUMERIC / 
    	COUNT(event_per_user),2) AS paying_to_buying_users_share, -- игроки с покупками и платящие / игроки с покупками - доля платящих среди с покупками
    ROUND(AVG(event_per_user),0) AS avg_event_per_user, -- среднее количество игроков с покупками
    ROUND((SUM(total_amount_per_user) / NULLIF(SUM(event_per_user), 0))::NUMERIC, 0) AS avg_amount_among_the_race, 	-- сумма покупок игроков с покупками / 
    																						-- сумма всех игроков с покупками - средний чек на игрока по расе
    ROUND(AVG(total_amount_per_user):: NUMERIC, 0) AS avg_total_amount_per_user -- средняя сумма покупок по расе
FROM fantasy.users
LEFT JOIN fantasy.race USING(race_id)
LEFT JOIN events_per_user USING(id)
GROUP BY race_id, race
ORDER BY race;
-- Самая популярная раса - HUMAN. Доля игроков с покупками по все расам варьируется от 60%(у расы Demon) до 62.9%(у расы Orc).
-- Доля всех платящих игроков среди игроков, совершивших покупки вообще, варьируется от 16.27%(у расы Elf) до 18.21%(у расы Demon).
-- Чем больше игроки покупают предметы за выполнение квестов, тем меньше тратят реальные деньги.

-- По среднему количеству покупок на одного игрока, совершившего покупку, выделяются две расы по наибольшему количеству - Angel(106.8) и Human(121.4).
-- Меньше всего у расы Demon. Игроки которой чаще остальных покупают предметы за реальные деньги.

-- По средней стоимости покупки на одного игрока, совершившего покупку, выделяются две расы по наибольшей стоимости - Elf(682.3) и Northman(761.5).
-- По средней суммарной стоимости покупки выделяются две расы по наибольшей стоимости - Elf(53 761.05) и Northman(62 522.21).
-- Самая популярная раса по общему количеству, по количеству совершивших покупку - HUMAN. Так же данная раса отличается самым высоким показателем
-- по среднему количеству покупок на одного игрока (121.4), но при этом самым низким средним чеком (403.13). 
-- Расы с "типичной" популярностью, так как: Northman, Hobbit, Orc. Игроки, выбравшие их, платят по среднему чеку и средней суммарной стоимостью покупки
-- как много (Northman), средне (Hobbit) и немного (Orc).

-- Результаты дают основания отвергнуть гипотезу маркетологов о том, что игра за персонажей разных рас требует примерно равного количества покупок предметов.




-- Статистика по странам регистрации игроков
WITH events_per_user AS(
        SELECT 
            id,
            COUNT(*) AS event_per_user,
            --
            -- приводим тип данных к ::NUMERIC, т.к. в БД у этой колонки  → amount
            -- тип данных REAL, что приводит к погрешности при расчете суммы покупок и среднего чека
            -- но в этом случае падает скорость обработки, т.к. изменение типа данных довольно затратно
            SUM(amount::NUMERIC) AS total_amount_per_user
            --
        FROM fantasy.events
        WHERE amount > 0
        GROUP BY id
)
SELECT
    location,
    COUNT(id) AS users, -- количество игроков по стране
    COUNT(event_per_user) AS buying_users, -- количество игроков по каждой стране с покупками
    ROUND(COUNT(event_per_user)*100:: NUMERIC/COUNT(id),2) AS buying_users_share, 	-- количество игроков по каждой стране с покупками / 
    																				--количество игроков по каждой стране - доля 
    ROUND(SUM(CASE WHEN payer = 1 AND event_per_user IS NOT NULL THEN 1 END) *100 :: NUMERIC / 
    	COUNT(event_per_user),2) AS paying_to_buying_users_share, -- игроки с покупками и платящие / игроки с покупками - доля платящих среди с покупками
    ROUND(AVG(event_per_user),0) AS avg_event_per_user, -- среднее количество игроков с покупками
    ROUND((SUM(total_amount_per_user) / NULLIF(SUM(event_per_user), 0))::NUMERIC, 0) AS avg_amount_among_the_race, 	-- сумма покупок игроков с покупками / 
    																						-- сумма всех игроков с покупками - средний чек на игрока по стране
    ROUND(AVG(total_amount_per_user):: NUMERIC, 0) AS avg_total_amount_per_user -- средняя сумма покупок по стране
FROM fantasy.users
LEFT JOIN fantasy.country USING(loc_id)
LEFT JOIN events_per_user USING(id)
GROUP BY loc_id, location
ORDER BY location;



-- Статистика по классам персонажам
WITH events_per_user AS(
        SELECT 
            id,
            COUNT(*) AS event_per_user,
            --
            -- приводим тип данных к ::NUMERIC, т.к. в БД у этой колонки  → amount
            -- тип данных REAL, что приводит к погрешности при расчете суммы покупок и среднего чека
            -- но в этом случае падает скорость обработки, т.к. изменение типа данных довольно затратно
            SUM(amount::NUMERIC) AS total_amount_per_user
            --
        FROM fantasy.events
        WHERE amount > 0
        GROUP BY id
)
SELECT
    class,
    COUNT(id) AS users, -- количество игроков классу
    COUNT(event_per_user) AS buying_users, -- количество игроков по классу с покупками
    ROUND(COUNT(event_per_user)*100:: NUMERIC/COUNT(id),2) AS buying_users_share, 	-- количество игроков по классу с покупками / 
    																				--количество игроков по классу - доля 
    ROUND(SUM(CASE WHEN payer = 1 AND event_per_user IS NOT NULL THEN 1 END) *100 :: NUMERIC / 
    	COUNT(event_per_user),2) AS paying_to_buying_users_share, -- игроки с покупками и платящие / игроки с покупками - доля платящих среди с покупками
    ROUND(AVG(event_per_user),0) AS avg_event_per_user, -- среднее количество игроков с покупками
    ROUND((SUM(total_amount_per_user) / NULLIF(SUM(event_per_user), 0))::NUMERIC, 0) AS avg_amount_among_the_race, 	-- сумма покупок игроков с покупками / 
    																						-- сумма всех игроков с покупками - средний чек на игрока по классу
    ROUND(AVG(total_amount_per_user):: NUMERIC, 0) AS avg_total_amount_per_user -- средняя сумма покупок по классу
FROM fantasy.users
LEFT JOIN fantasy.classes USING(class_id)
LEFT JOIN events_per_user USING(id)
GROUP BY class_id, class
ORDER BY class;




-- Показатели покупок по полу персонажей
WITH events_per_user AS(
        SELECT 
            id,
            COUNT(*) AS event_per_user,
            --
            -- приводим тип данных к ::NUMERIC, т.к. в БД у этой колонки  → amount
            -- тип данных REAL, что приводит к погрешности при расчете суммы покупок и среднего чека
            -- но в этом случае падает скорость обработки, т.к. изменение типа данных довольно затратно
            SUM(amount::NUMERIC) AS total_amount_per_user
            --
        FROM fantasy.events
        WHERE amount > 0
        GROUP BY id
)
SELECT
    pers_gender,
    COUNT(id) AS users, -- количество игроков полу
    COUNT(event_per_user) AS buying_users, -- количество игроков по полу с покупками
    ROUND(COUNT(event_per_user)*100:: NUMERIC/COUNT(id),2) AS buying_users_share, 	-- количество игроков по полу с покупками / 
    																				--количество игроков по полу - доля 
    ROUND(SUM(CASE WHEN payer = 1 AND event_per_user IS NOT NULL THEN 1 END) *100 :: NUMERIC / 
    	COUNT(event_per_user),2) AS paying_to_buying_users_share, -- игроки с покупками и платящие / игроки с покупками - доля платящих среди с покупками
    ROUND(AVG(event_per_user),0) AS avg_event_per_user, -- среднее количество игроков с покупками
    ROUND((SUM(total_amount_per_user) / NULLIF(SUM(event_per_user), 0))::NUMERIC, 0) AS avg_amount_among_the_race, 	-- сумма покупок игроков с покупками / 
    																						-- сумма всех игроков с покупками - средний чек на игрока по полу
    ROUND(AVG(total_amount_per_user):: NUMERIC, 0) AS avg_total_amount_per_user -- средняя сумма покупок по полу
FROM fantasy.users
LEFT JOIN events_per_user USING(id)
GROUP BY pers_gender
ORDER BY pers_gender;


-- Абсолютное большинство игроков являются выходцами из United States (19 057). Количество платящих игроков - 11 836 (2 114 из них за реальные деньги). 
-- Так же их характеризует средний показатель по среднему чеку (533) и высокий - по средним суммарным платежам (50 748).

-- Лидеры по классам персонажа: Knight (4 163 (731 за реальные деньги) платящих игроков из 6 686) и 
-- Paladin (2 049 (345 за реальные деньги) платящих игроков из 3 333). 
-- Для Knight - средний показатель по среднему чеку (507) и высокие суммарные платежи (53 802). 
-- Для Paladin - средний показатель по среднему чеку (544) и ниже среднего суммарные платежи (45 921).

-- Мужчины: всего игроков - 11 288, с покупками - 7 048, платящие - 1 238, средний чек - 459, средние суммарные платежи - 48 029
-- Женщины: всего игроков - 10 321, с покупками - 6 358, платящие - 1 139, средний чек - 606, средние суммарные платежи - 51 723
-- Мужчин почти на 1 тыс больше среди игроков. Их характеризует немного большая доля с покупками и 
-- немного меньшая доля по показателю платящих, меньший средний чек и меньшие средние суммарные платежи
-- Мужчины предпочитают платить исходя из заработка на квестах. 
-- Мужчины немного лучше играют в игры, а женщины больше платят реальные деньги во время прохождение игры.





	

-- Часть 3. Заключение

-- Доля платящих игроков составляет 0.1769 (точный показатель - 17.69%). 
-- Наиболее типичной расой по платящим игрокам является Human (17.60%). Она же является наиболее популярной расой среди игроков.
-- Чаще всего совершают покупки игроки, которые выбирают в качестве расы своего персонажа - Demon. Но при этом данная раса
-- является наименее популярной среди всех игроков. Раса Demon обладает малой выборкой. Поэтому показатель доли этой расы нельзя применить
-- ко всей выборке по расам. Тогда как лидеры по количеству игроков обладают существенной выборкой и их доли платящих ближе к средней по всем данным.
-- Довести показатель всей выборки до показателя доли платящих у расы Demon может потребовать существенных дополнительных расходов на маркетинговые компании.
-- Выбор расы влияет на долю платящих игроков.


-- Всего внутриигровых покупок - 1.3 млн.
-- Имеется сильная разница между средним (525.69) значением покупки и медианным (74.86). Среднее больше медианы.
-- В выборке много малых значений стоимости покупки и мало крупных, из-за чего среднее значение сильно выше медианы.
-- Показатели медиан совпадают.
-- Влияние нулевых покупок на статистические показатели не существенное.
-- Стандартное отклонение гораздо выше среднего. Вероятно имеется большой разброс данных по стоимости покупки.


-- Количество нулевых покупок - 907. Все нулевые покупки - это покупки эпического предмета с кодом 6010 Book of Legends
-- Доля нулевых покупок от общего числа покупок составляет 0.00069 (0.069%)
-- Крупные покупки
-- В выборке покупок стоимостью выше 50 000 по суммарной стоимости и 
-- количеству покупок большинство составляют выходцы из United States. Классы персонажей разнообразны.
-- Покупаемый предмет - 6010 Book of Legends. 
-- Абсолютный лидер: игрок выходец из United States с персонажем Knight, 
-- суммарная стоимость покупок - 14 млн, количеством покупок - 117.



-- ТОП-2 самых популярных предметов: 6010 Book of Legends - 1 004 516 шт. на сумму 436 921 700, 6011 Bag of Holding - 271 875 шт. на сумму 240 579 800.
-- Самый популярный предмет - 6010 Book of Legends. Его доля от общего количества покупок - 76,87%. Его купили 12 194 игроков. 
-- Что составляет 88,41% от общего числа платящих игроков
-- Второй самый популярный предмет - 6011 Bag of Holdingю Его доля от общего количества покупок - 20,80%. Его купили 11 968 игроков. 
-- Что составляет 86,77% от общего числа платящих игроков.
-- Все остальные предметы купили 30 380 раз на сумму 9,5 млн, что составляет 2,32% от количества всех покупок.
-- Остальные предметы купили 5 609 игроков, что составляет 40,67% от всех игроков с покупками.

-- Выводы
-- ТОП-2 предмета обеспечивают 97% продаж. Что говорит о крайне высокой поляризации спроса. 
-- 6010 Book of Legends вероятно воспринимается как "must-have". Тогда как 6011 Bag of Holding покупается в качестве чуть менее обязательного дополнения.
-- Оба предмета являются часть очевидного и самого популярного билда для прохождения игры. Остальные предметы составляют меньше 3% всех покупок.
-- Они менее доступны в игре и/или их использование не очевидны и/или не по нраву игрокам, несмотря на то, что 41% игроков купили остальные предметы.
-- Рекомендации:
-- Сфокусировать на продаже предметов из ТОП-2 с целью улучшения среднего чека по данным товарам
-- Узнать причину покупок предметов вне ТОП-2 и проверить ценообразование и позиционирование остальных предметов.

-- Раса Human является лидером покупок предметов как из ТОП-2, так вне его.
-- 3 455 игроков (25% всех игроков от числа всех с покупками) из расы Human совершили 389 680 покупок (30% от всех покупок) на сумму 120 117 376 предметов из ТОП-2
-- 1 606 игроков (12% всех игроков от числа всех с покупками) из расы Human совершили 8 177 покупок (0,63% от всех покупок) на сумму 2 603 583 предметов вне ТОП-2





-- Самая популярная раса - HUMAN. Доля игроков с покупками по все расам варьируется от 60%(у расы Demon) до 62.9%(у расы Orc).
-- Доля всех платящих игроков среди игроков, совершивших покупки вообще, варьируется от 16.27%(у расы Elf) до 18.21%(у расы Demon).
-- Чем больше игроки покупают предметы за выполнение квестов, тем меньше тратят реальные деньги.

-- По среднему количеству покупок на одного игрока, совершившего покупку, выделяются две расы по наибольшему количеству - Angel(106.8) и Human(121.4).
-- Меньше всего у расы Demon. Игроки которой чаще остальных покупают предметы за реальные деньги.

-- По средней стоимости покупки на одного игрока, совершившего покупку, выделяются две расы по наибольшей стоимости - Elf(682.3) и Northman(761.5).
-- По средней суммарной стоимости покупки выделяются две расы по наибольшей стоимости - Elf(53 761.05) и Northman(62 522.21).
-- Самая популярная раса по общему количеству, по количеству совершивших покупку - HUMAN. Так же данная раса отличается самым высоким показателем
-- по среднему количеству покупок на одного игрока (121.4), но при этом самым низким средним чеком (403.13). 
-- Расы с "типичной" популярностью, так как: Northman, Hobbit, Orc. Игроки, выбравшие их, платят по среднему чеку и средней суммарной стоимостью покупки
-- как много (Northman), средне (Hobbit) и немного (Orc).

-- Результаты дают основания отвергнуть гипотезу маркетологов о том, что игра за персонажей разных рас требует примерно равного количества покупок предметов.
	

-- Абсолютное большинство игроков являются выходцами из United States (19 057). Количество платящих игроков - 11 836 (2 114 из них за реальные деньги). 
-- Так же их характеризует средний показатель по среднему чеку (533) и высокий - по средним суммарным платежам (50 748).

-- Лидеры по классам персонажа: Knight (4 163 (731 за реальные деньги) платящих игроков из 6 686) и 
-- Paladin (2 049 (345 за реальные деньги) платящих игроков из 3 333). 
-- Для Knight - средний показатель по среднему чеку (507) и высокие суммарные платежи (53 802). 
-- Для Paladin - средний показатель по среднему чеку (544) и ниже среднего суммарные платежи (45 921).

-- Мужчины: всего игроков - 11 288, с покупками - 7 048, платящие - 1 238, средний чек - 459, средние суммарные платежи - 48 029
-- Женщины: всего игроков - 10 321, с покупками - 6 358, платящие - 1 139, средний чек - 606, средние суммарные платежи - 51 723
-- Мужчин почти на 1 тыс больше среди игроков. Их характеризует немного большая доля с покупками и 
-- немного меньшая доля по показателю платящих, меньший средний чек и меньшие средние суммарные платежи
-- Мужчины предпочитают платить исходя из заработка на квестах. 
-- Мужчины немного лучше играют в игры, а женщины больше платят реальные деньги во время прохождение игры.


-- Типичный игрок - это выходец из United States, играющий за Knight расы Human.
-- Маркетинговые компании должны быть направлены на данную группу игроков.


