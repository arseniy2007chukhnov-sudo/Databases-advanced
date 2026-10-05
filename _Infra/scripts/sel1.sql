-- 1. Каждый пользователь имеет одинаковое количество измерений?
SELECT u.id AS polzovatel_id,
       u.uniq_code,
       u.full_name,
       COUNT(p.id) AS cnt_pachki
FROM polzovateli u
LEFT JOIN pachki p ON p.polzovatel_id = u.id
GROUP BY u.id, u.uniq_code, u.full_name
ORDER BY u.id;