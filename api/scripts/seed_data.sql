-- Datos ficticios para pruebas (Colmena)

INSERT INTO zonas_protegidas (codigo, nombre, tipo_zona_codigo, geom) VALUES
    ('a1b2c3d4-1111-4111-8111-111111111111', 'Reserva Manuripi', 'AREA_PROTEGIDA',
     ST_GeogFromText('POLYGON((-68.0 -11.0, -67.0 -11.0, -67.0 -12.0, -68.0 -12.0, -68.0 -11.0))')),
    ('a1b2c3d4-2222-4222-8222-222222222222', 'Territorio Indígena Multiétnico II', 'TERRITORIO_INDIGENA',
     ST_GeogFromText('POLYGON((-69.0 -10.5, -68.0 -10.5, -68.0 -11.5, -69.0 -11.5, -69.0 -10.5))')),
    ('a1b2c3d4-3333-4333-8333-333333333333', 'Bajo Madidi', 'AREA_PROTEGIDA',
     ST_GeogFromText('POLYGON((-68.5 -10.0, -67.5 -10.0, -67.5 -11.0, -68.5 -11.0, -68.5 -10.0))'));

INSERT INTO normativa (codigo, titulo, texto_resumen) VALUES
    ('b1b2c3d4-1111-4111-8111-111111111111', 'Ley 1333 - Ley de Medio Ambiente', 'Marco regulatorio para la protección del medio ambiente en Bolivia.'),
    ('b1b2c3d4-2222-4222-8222-222222222222', 'D.S. 28592 - Reglamento Ambiental Minero', 'Regula actividades mineras y sus impactos ambientales.'),
    ('b1b2c3d4-3333-4333-8333-333333333333', 'Código Penal art. 216', 'Sanciones penales por daño ambiental y extracción ilegal.');

INSERT INTO reportes (codigo, ubicacion, tamano_draga_codigo, tiempo_operacion_codigo, personas_visibles, motobombas_visibles, estado_codigo, fecha_creacion) VALUES
    ('c1000001-0001-4001-8001-000000000001', ST_GeogFromText('POINT(-67.5441 -11.4162)'), 'MEDIANA', 'VARIOS_DIAS', true, true, 'nuevo', '2026-06-03'),
    ('c1000001-0002-4002-8002-000000000002', ST_GeogFromText('POINT(-68.7604 -11.1587)'), 'PEQUENA', 'MENOS_1_DIA', false, true, 'revisado', '2026-06-07'),
    ('c1000001-0003-4003-8003-000000000003', ST_GeogFromText('POINT(-68.3372 -10.9823)'), 'GRANDE', 'MAS_1_SEMANA', true, true, 'escalado', '2026-06-11'),
    ('c1000001-0004-4004-8004-000000000004', ST_GeogFromText('POINT(-67.8701 -11.7210)'), 'MEDIANA', 'VARIOS_DIAS', false, true, 'nuevo', '2026-06-15'),
    ('c1000001-0005-4005-8005-000000000005', ST_GeogFromText('POINT(-68.1200 -11.3000)'), 'GRANDE', 'MAS_1_SEMANA', true, false, 'revisado', '2026-06-20'),
    ('c1000001-0006-4006-8006-000000000006', ST_GeogFromText('POINT(-67.9500 -10.8500)'), 'PEQUENA', 'MENOS_1_DIA', false, false, 'nuevo', '2026-07-01'),
    ('c1000001-0007-4007-8007-000000000007', ST_GeogFromText('POINT(-68.4100 -11.6000)'), 'MEDIANA', 'VARIOS_DIAS', true, true, 'escalado', '2026-07-10'),
    ('c1000001-0008-4008-8008-000000000008', ST_GeogFromText('POINT(-67.7000 -11.0500)'), 'GRANDE', 'MAS_1_SEMANA', true, true, 'nuevo', '2026-07-20');

INSERT INTO contacto_informante (reporte_codigo, alias, celular) VALUES
    ('c1000001-0002-4002-8002-000000000002', 'Río Claro', '725-11445'),
    ('c1000001-0004-4004-8004-000000000004', 'Luz Sur', '711-22331'),
    ('c1000001-0007-4007-8007-000000000007', 'Vigía Norte', '733-55889');

INSERT INTO notas_reporte (reporte_codigo, texto) VALUES
    ('c1000001-0001-4001-8001-000000000001', 'Actividad sobre margen del río con remoción visible de sedimentos.'),
    ('c1000001-0003-4003-8003-000000000003', 'Flujo constante de maquinaria sobre cauce secundario.'),
    ('c1000001-0005-4005-8005-000000000005', 'Draga grande operando de noche.'),
    ('c1000001-0007-4007-8007-000000000007', 'Dos dragas medianas operando en paralelo.'),
    ('c1000001-0008-4008-8008-000000000008', 'Operación a gran escala con múltiples equipos.');

INSERT INTO evaluaciones (reporte_codigo, factor_mercurio, mercurio_estimado_kg, zona_codigo, normativa_codigo, nivel_riesgo_codigo) VALUES
    ('c1000001-0001-4001-8001-000000000001', 5.0, 18.4, 'a1b2c3d4-1111-4111-8111-111111111111', 'b1b2c3d4-1111-4111-8111-111111111111', 'ALTO'),
    ('c1000001-0002-4002-8002-000000000002', 4.0, 6.2, NULL, 'b1b2c3d4-1111-4111-8111-111111111111', 'MEDIO'),
    ('c1000001-0003-4003-8003-000000000003', 6.0, 22.8, 'a1b2c3d4-3333-4333-8333-333333333333', 'b1b2c3d4-2222-4222-8222-222222222222', 'ALTO'),
    ('c1000001-0004-4004-8004-000000000004', 5.0, 10.1, NULL, 'b1b2c3d4-1111-4111-8111-111111111111', 'MEDIO'),
    ('c1000001-0005-4005-8005-000000000005', 6.0, 25.0, 'a1b2c3d4-2222-4222-8222-222222222222', 'b1b2c3d4-3333-4333-8333-333333333333', 'ALTO'),
    ('c1000001-0007-4007-8007-000000000007', 5.5, 15.3, 'a1b2c3d4-1111-4111-8111-111111111111', 'b1b2c3d4-2222-4222-8222-222222222222', 'ALTO'),
    ('c1000001-0008-4008-8008-000000000008', 6.0, 30.0, 'a1b2c3d4-3333-4333-8333-333333333333', 'b1b2c3d4-1111-4111-8111-111111111111', 'ALTO');

INSERT INTO estimacion_economica (reporte_codigo, valor_bs) VALUES
    ('c1000001-0001-4001-8001-000000000001', 78000),
    ('c1000001-0002-4002-8002-000000000002', 21400),
    ('c1000001-0003-4003-8003-000000000003', 124500),
    ('c1000001-0004-4004-8004-000000000004', 36200),
    ('c1000001-0005-4005-8005-000000000005', 105000),
    ('c1000001-0007-4007-8007-000000000007', 68000),
    ('c1000001-0008-4008-8008-000000000008', 150000);
