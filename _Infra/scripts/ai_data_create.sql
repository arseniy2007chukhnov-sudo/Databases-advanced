
-- 1. Очистка данных для обеспечения перезапускаемости
-- Удаляем измерения, затем пачки, затем только добавленных пользователей (id > 3)
DELETE FROM parametry;
DELETE FROM pachki;
DELETE FROM polzovateli WHERE id > 3;

-- 2. Добавление новых пользователей (id 4, 5, 6)
INSERT INTO polzovateli (id, uniq_code, full_name, dolzhnost_id) VALUES (4, 'USR-004', 'Кузнецов Алексей Николаевич', 1);
INSERT INTO polzovateli (id, uniq_code, full_name, dolzhnost_id) VALUES (5, 'USR-005', 'Смирнов Дмитрий Олегович', 2);
INSERT INTO polzovateli (id, uniq_code, full_name, dolzhnost_id) VALUES (6, 'USR-006', 'Волкова Елена Викторовна', 1);

-- 3. Вставка пачек (18 шт., id 1..18, ровно по 3 на каждого из 6 пользователей)
-- Пользователь 1 (Иванов): ДМК (1), ВР (2), ДМК (3)
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (1, 'PCH-001', 1, 1, 5, DATE '2026-09-01');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (2, 'PCH-002', 2, 1, 5, DATE '2026-09-02');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (3, 'PCH-003', 1, 1, 5, DATE '2026-09-03');

-- Пользователь 2 (Петров): ВР (4), ДМК (5), ВР (6)
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (4, 'PCH-004', 2, 2, 5, DATE '2026-09-04');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (5, 'PCH-005', 1, 2, 5, DATE '2026-09-05');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (6, 'PCH-006', 2, 2, 5, DATE '2026-09-06');

-- Пользователь 3 (Сидорова): ДМК (7), ВР (8), ДМК (9)
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (7, 'PCH-007', 1, 3, 5, DATE '2026-09-07');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (8, 'PCH-008', 2, 3, 5, DATE '2026-09-08');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (9, 'PCH-009', 1, 3, 5, DATE '2026-09-09');

-- Пользователь 4 (Кузнецов): ВР (10), ДМК (11), ВР (12)
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (10, 'PCH-010', 2, 4, 5, DATE '2026-09-10');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (11, 'PCH-011', 1, 4, 5, DATE '2026-09-11');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (12, 'PCH-012', 2, 4, 5, DATE '2026-09-12');

-- Пользователь 5 (Смирнов): ДМК (13), ВР (14), ДМК (15)
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (13, 'PCH-013', 1, 5, 5, DATE '2026-09-13');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (14, 'PCH-014', 2, 5, 5, DATE '2026-09-14');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (15, 'PCH-015', 1, 5, 5, DATE '2026-09-15');

-- Пользователь 6 (Волкова): ВР (16), ДМК (17), ВР (18)
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (16, 'PCH-016', 2, 6, 5, DATE '2026-09-16');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (17, 'PCH-017', 1, 6, 5, DATE '2026-09-17');
INSERT INTO pachki (id, uniq_code, tip_oborudovaniya_id, polzovatel_id, quantity, created_date) VALUES (18, 'PCH-018', 2, 6, 5, DATE '2026-09-18');

-- 4. Вставка измерений (90 строк, id 1..90, uniq_code 'PAR-001'..'PAR-090')
-- Пачки 1-3 (Пользователь 1: ДМК, ВР, ДМК)
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (1, 'PAR-001', 1, 1, '120', 1);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (2, 'PAR-002', 1, 2, '15.5', 1);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (3, 'PAR-003', 1, 3, '750', 1);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (4, 'PAR-004', 1, 4, '12', 1);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (5, 'PAR-005', 1, 5, '3', 1);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (6, 'PAR-006', 2, 1, '200', 2);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (7, 'PAR-007', 2, 2, '16.0', 2);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (8, 'PAR-008', 2, 3, '752', 2);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (9, 'PAR-009', 2, 4, '25', 2);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (10, 'PAR-010', 2, 6, '45', 2);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (11, 'PAR-011', 1, 1, '135', 3);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (12, 'PAR-012', 1, 2, '14.2', 3);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (13, 'PAR-013', 1, 3, '749', 3);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (14, 'PAR-014', 1, 4, '45', 3);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (15, 'PAR-015', 1, 5, '2', 3);

-- Пачки 4-6 (Пользователь 2: ВР, ДМК, ВР)
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (16, 'PAR-016', 2, 1, '220', 4);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (17, 'PAR-017', 2, 2, '17.5', 4);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (18, 'PAR-018', 2, 3, '754', 4);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (19, 'PAR-019', 2, 4, '31', 4);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (20, 'PAR-020', 2, 6, '60', 4);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (21, 'PAR-021', 1, 1, '110', 5);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (22, 'PAR-022', 1, 2, '10.0', 5);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (23, 'PAR-023', 1, 3, '748', 5);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (24, 'PAR-024', 1, 4, '50', 5);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (25, 'PAR-025', 1, 5, '0', 5);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (26, 'PAR-026', 2, 1, '190', 6);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (27, 'PAR-027', 2, 2, '18.8', 6);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (28, 'PAR-028', 2, 3, '751', 6);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (29, 'PAR-029', 2, 4, '44', 6);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (30, 'PAR-030', 2, 6, '30', 6);

-- Пачки 7-9 (Пользователь 3: ДМК, ВР, ДМК)
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (31, 'PAR-031', 1, 1, '150', 7);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (32, 'PAR-032', 1, 2, '19.9', 7);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (33, 'PAR-033', 1, 3, '755', 7);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (34, 'PAR-034', 1, 4, '33', 7);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (35, 'PAR-035', 1, 5, '7', 7);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (36, 'PAR-036', 2, 1, '210', 8);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (37, 'PAR-037', 2, 2, '20.5', 8);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (38, 'PAR-038', 2, 3, '753', 8);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (39, 'PAR-039', 2, 4, '22', 8);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (40, 'PAR-040', 2, 6, '55', 8);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (41, 'PAR-041', 1, 1, '95', 9);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (42, 'PAR-042', 1, 2, '13.1', 9);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (43, 'PAR-043', 1, 3, '747', 9);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (44, 'PAR-044', 1, 4, '55', 9);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (45, 'PAR-045', 1, 5, '1', 9);

-- Пачки 10-12 (Пользователь 4: ВР, ДМК, ВР)
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (46, 'PAR-046', 2, 1, '240', 10);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (47, 'PAR-047', 2, 2, '21.0', 10);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (48, 'PAR-048', 2, 3, '758', 10);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (49, 'PAR-049', 2, 4, '5', 10);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (50, 'PAR-050', 2, 6, '85', 10);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (51, 'PAR-051', 1, 1, '165', 11);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (52, 'PAR-052', 1, 2, '12.8', 11);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (53, 'PAR-053', 1, 3, '756', 11);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (54, 'PAR-054', 1, 4, '15', 11);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (55, 'PAR-055', 1, 5, '14', 11);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (56, 'PAR-056', 2, 1, '180', 12);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (57, 'PAR-057', 2, 2, '16.8', 12);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (58, 'PAR-058', 2, 3, '745', 12);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (59, 'PAR-059', 2, 4, '58', 12);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (60, 'PAR-060', 2, 6, '15', 12);

-- Пачки 13-15 (Пользователь 5: ДМК, ВР, ДМК)
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (61, 'PAR-061', 1, 1, '140', 13);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (62, 'PAR-062', 1, 2, '10.5', 13);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (63, 'PAR-063', 1, 3, '759', 13);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (64, 'PAR-064', 1, 4, '28', 13);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (65, 'PAR-065', 1, 5, '9', 13);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (66, 'PAR-066', 2, 1, '230', 14);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (67, 'PAR-067', 2, 2, '22.5', 14);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (68, 'PAR-068', 2, 3, '760', 14);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (69, 'PAR-069', 2, 4, '35', 14);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (70, 'PAR-070', 2, 6, '95', 14);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (71, 'PAR-071', 1, 1, '105', 15);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (72, 'PAR-072', 1, 2, '8.5', 15);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (73, 'PAR-073', 1, 3, '744', 15);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (74, 'PAR-074', 1, 4, '50', 15);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (75, 'PAR-075', 1, 5, '0', 15);

-- Пачки 16-18 (Пользователь 6: ВР, ДМК, ВР)
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (76, 'PAR-076', 2, 1, '205', 16);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (77, 'PAR-077', 2, 2, '21.5', 16);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (78, 'PAR-078', 2, 3, '752', 16);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (79, 'PAR-079', 2, 4, '27', 16);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (80, 'PAR-080', 2, 6, '70', 16);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (81, 'PAR-081', 1, 1, '125', 17);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (82, 'PAR-082', 1, 2, '9.3', 17);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (83, 'PAR-083', 1, 3, '742', 17);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (84, 'PAR-084', 1, 4, '6', 17);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (85, 'PAR-085', 1, 5, '4', 17);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (86, 'PAR-086', 2, 1, '260', 18);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (87, 'PAR-087', 2, 2, '24.0', 18);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (88, 'PAR-088', 2, 3, '762', 18);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (89, 'PAR-089', 2, 4, '14', 18);
INSERT INTO parametry (id, uniq_code, tip_oborudovaniya_id, tip_parametra_id, value, pachka_id) VALUES (90, 'PAR-090', 2, 6, '140', 18);

