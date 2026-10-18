-- OPTIONAL demo data for a NEW EMPTY EL BEM 2 database only.
-- Clearly fictional masters and products; don't present as real salon records.
insert into public.services(id,name,category,price,duration,image,description) values
('s1','Женская стрижка','Волосы',300,60,'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=900','Цена от; уточняется в салоне'),
('s2','Окрашивание волос','Волосы',1500,150,'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=900','Цена от; уточняется в салоне'),
('s3','Макияж','Макияж',500,60,'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=900','Цена от; уточняется в салоне'),
('s4','Маникюр','Ногти',400,75,'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=900','Цена от; уточняется в салоне'),
('s5','Наращивание ресниц','Ресницы и брови',800,120,'https://images.unsplash.com/photo-1583001931096-959e9a1a6223?auto=format&fit=crop&w=900','Цена от; уточняется в салоне'),
('s6','Коррекция бровей','Ресницы и брови',200,30,'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?auto=format&fit=crop&w=900','Цена от; уточняется в салоне')
on conflict(id) do nothing;
insert into public.masters(id,name,specialty,image,"serviceIds") values
('m1','Демо-мастер по волосам','Стрижка и окрашивание — DEMO','https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=700',array['s1','s2']),
('m2','Демо-визажист','Макияж и ресницы — DEMO','https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43?auto=format&fit=crop&w=700',array['s3','s5','s6']),
('m3','Демо-мастер маникюра','Маникюр — DEMO','https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=700',array['s4'])
on conflict(id) do nothing;
insert into public.products(id,name,category,price,image,description,demo) values
('p1','Шампунь для ухода','Для волос',650,'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&w=800','Демонстрационный товар',true),
('p2','Маска для волос','Для волос',890,'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?auto=format&fit=crop&w=800','Демонстрационный товар',true),
('p3','Крем для рук','Уход',390,'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?auto=format&fit=crop&w=800','Демонстрационный товар',true),
('p4','Сыворотка для лица','Уход',990,'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=800','Демонстрационный товар',true),
('p5','Масло для волос','Для волос',520,'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?auto=format&fit=crop&w=800','Демонстрационный товар',true),
('p6','Набор для ухода','Наборы',1590,'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=800','Демонстрационный товар',true)
on conflict(id) do nothing;
insert into public.site_content(id,data) values (1,'{"heroTitle":"Красота, которая","heroEmphasis":"вдохновляет.","heroSubtitle":"Искусство заботы о себе. Продуманные услуги красоты, внимание к деталям и время только для вас.","heroImage":"https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1250","aboutTitle":"Красота начинается с заботы","aboutText":"EL BEM — салон красоты в Узгене. Иллюстративные материалы; информацию уточните у владельца.","academyTitle":"Профессия, которая вдохновляет","academyText":"Обучение: программа и стоимость уточняются.","academyImage":"https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900","whatsapp":"","address":"Узген, Кыргызстан — адрес уточняется","openingHours":"Часы работы уточняются","musicUrl":"","musicEnabled":false,"shopEnabled":true}'::jsonb)
on conflict(id) do nothing;
