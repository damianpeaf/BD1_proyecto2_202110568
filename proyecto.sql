drop database if exists proyecto_2;
create database proyecto_2;
use proyecto_2;

## Carrera
create table carrera(
    id_carrera bigint primary key auto_increment,
    nombre varchar(50) unique not null
) auto_increment = 0;


## Estudiate
create table estudiante(
    carnet bigint primary key,
    nombres varchar(50) not null,
    apellidos varchar(50) not null,
    fecha_nacimiento date not null,
    correo varchar(50) not null,
    telefono int not null,
    direccion varchar(50) not null,
    cui bigint(13) not null,
    carrera bigint not null,
    creditos_obtenidos int not null default 0,
    foreign key (carrera) references carrera(id_carrera)
);


## Docente
create table docente(
    siif bigint primary key,
    nombres varchar(50) not null,
    apellidos varchar(50) not null,
    fecha_nacimiento date not null,
    correo varchar(50) not null,
    telefono int not null,
    direccion varchar(50) not null,
    cui bigint(13) not null
);

## Curso
create table curso(
    codigo bigint primary key,
    nombre varchar(50) not null,
    creditos_necesarios int not null,
    creditos_obtenidos int not null,
    carrera bigint not null,
    obligatorio boolean not null,
    foreign key (carrera) references carrera(id_carrera)
);

## Curso Habilitado
create table curso_habilitado(
    id_habilitacion bigint primary key auto_increment,
    codigo_curso bigint not null,
    ciclo enum('1S', '2S', 'VJ', 'VD') not null,
    docente_siif bigint not null,
    cupo_maximo int not null,
    cupo_actual int not null default 0,
    anio INT not null default 2023,
    seccion char(1) not null,
    foreign key (codigo_curso) references curso(codigo),
    foreign key (docente_siif) references docente(siif)
);

## Horario
create table horario(
    id_horario int primary key auto_increment,
    id_habilitacion bigint not null,
    dia tinyint not null check ( dia between 1 and 7 ) ,
    horario varchar(50) not null,
    foreign key (id_habilitacion) references curso_habilitado(id_habilitacion)
);

## Asignacion
create table asignacion(
    id_asignacion bigint primary key auto_increment,
    id_habilitacion bigint not null,
    carnet_estudiante bigint not null,
    fecha_desasignacion date,
    foreign key (id_habilitacion) references curso_habilitado(id_habilitacion),
    foreign key (carnet_estudiante) references estudiante(carnet)
);

## Nota
create table nota(
    id_nota bigint primary key auto_increment,
    id_asignacion bigint not null,
    nota decimal(5,2) not null check ( nota between 0 and 100 ),
    foreign key (id_asignacion) references asignacion(id_asignacion)
);


## Acta
create table acta(
    id_acta bigint primary key auto_increment,
    id_habilitacion bigint not null,
    fecha date not null,
    foreign key (id_habilitacion) references curso_habilitado(id_habilitacion)
);

create table historial_transaccion(
    fecha_hora datetime not null,
    descripcion varchar(100) not null,
    tipo varchar(10) not null
);



## Procedimientos y Funciones

### Utiles

#### Validar correo
Delimiter //
create function validar_correo(
    p_correo varchar(50)
)
returns boolean
begin
    declare v_correo varchar(50);
    declare v_valido boolean default false;
    set v_correo = p_correo;
    if v_correo like '%@%' and v_correo like '%.com%' then
        set v_valido = true;
    end if;
    return v_valido;
end //

#### Carrera existe
Delimiter //
create function carrera_existe_id(
    p_id_carrera bigint
)
returns boolean
begin
    declare v_existe boolean default false;
    if (select count(*) from carrera where id_carrera = p_id_carrera) > 0 then
        set v_existe = true;
    end if;
    return v_existe;
end //

DELIMITER //
create function carrera_existe_nombre(
    p_nombre varchar(50)
)
returns boolean
begin
    declare v_existe boolean default false;
    if (select count(*) from carrera where LOWER(nombre) = LOWER(p_nombre)) > 0 then
        set v_existe = true;
    end if;
    return v_existe;
end //

#### Docente existe
Delimiter //
create function docente_existe(
    p_siif bigint
)
returns boolean
begin
    declare v_existe boolean default false;
    if (select count(*) from docente where siif = p_siif) > 0 then
        set v_existe = true;
    end if;
    return v_existe;
end //

#### Curso existe
Delimiter //
create function curso_existe(
    p_codigo bigint
)
returns boolean
begin
    declare v_existe boolean default false;
    if (select count(*) from curso where codigo = p_codigo) > 0 then
        set v_existe = true;
    end if;
    return v_existe;
end //

#### Curso habilitado existe
Delimiter //
create function curso_habilitado_existe(
    p_id_habilitacion bigint
)
returns boolean
begin
    declare v_existe boolean default false;
    if (select count(*) from curso_habilitado where id_habilitacion = p_id_habilitacion) > 0 then
        set v_existe = true;
    end if;
    return v_existe;
end //

# existe curso habilitado en el ciclo, seccion y anio indicados
Delimiter //
create function curso_habilitado_existe_ciclo_seccion_anio(
    p_codigo_curso bigint,
    p_ciclo enum('1S', '2S', 'VJ', 'VD'),
    p_seccion char(1)
)
returns boolean
begin
    declare v_existe boolean default false;
    if (select count(*) from curso_habilitado where codigo_curso = p_codigo_curso and ciclo = p_ciclo and seccion = p_seccion and anio = 2023) > 0 then
        set v_existe = true;
    end if;
    return v_existe;
end //

####Registrar Estudiante
Delimiter //
create procedure registrarEstudiante(
    p_carnet bigint,
    p_nombres varchar(50),
    p_apellidos varchar(50),
    p_fecha_nacimiento date,
    p_correo varchar(50),
    p_telefono int,
    p_direccion varchar(50),
    p_cui bigint,
    p_carrera bigint
)
begin

   # Validar que la carrera exista
    if (not carrera_existe_id(p_carrera)) then
          signal sqlstate '45000' set message_text = 'La carrera no existe';
    end if;
    # Validar que el correo sea valido
    if not validar_correo(p_correo) then
        signal sqlstate '45000' set message_text = 'El correo no es valido';
    end if;
    start transaction;
    insert into estudiante values(p_carnet, p_nombres, p_apellidos, p_fecha_nacimiento, p_correo, p_telefono, p_direccion, p_cui, p_carrera, 0);
    commit;
    select 'Estudiante registrado exitosamente'as resultado;
end //

####Registrar carrera
Delimiter //
create procedure crearCarrera(
    p_nombre varchar(50)
)
begin

    # Validar que la carrera no exista
    if carrera_existe_nombre(p_nombre) then
        signal sqlstate '45000' set message_text = 'La carrera ya existe';
    end if;
    start transaction;
    insert into carrera(nombre) values(p_nombre);
    commit;
    select 'Carrera registrada exitosamente'as resultado;
end //

####Registrar docente
Delimiter //
create procedure registrarDocente(
    p_nombres varchar(50),
    p_apellidos varchar(50),
    p_fecha_nacimiento date,
    p_correo varchar(50),
    p_telefono int,
    p_direccion varchar(50),
    p_cui bigint,
    p_siif bigint
)
begin

    # Validar que el docente no exista
    if docente_existe(p_siif) then
        signal sqlstate '45000' set message_text = 'Ya existe un docente con ese siif';
    end if;
    # Validar que el correo sea valido
    if not validar_correo(p_correo) then
        signal sqlstate '45000' set message_text = 'El correo no es valido';
    end if;
    start transaction;
    insert into docente values(p_siif, p_nombres, p_apellidos, p_fecha_nacimiento, p_correo, p_telefono, p_direccion, p_cui);
    commit;
    select 'Docente registrado exitosamente' as resultado;
end //

####Registrar curso
Delimiter //
create procedure crearCurso(
    p_codigo bigint,
    p_nombre varchar(50),
    p_creditos_necesarios int,
    p_creditos_obtenidos int,
    p_carrera bigint,
    p_obligatorio int
)
begin
    declare v_obligatorio boolean;


    -- verificar que sea 0 o 1
    if p_obligatorio not in (0,1) then
        signal sqlstate '45000' set message_text = 'El campo obligatorio debe ser 0 o 1';
    end if;
    -- convertir el int a boolean
    if p_obligatorio = 1 then
        set v_obligatorio = true;
    else
        set v_obligatorio = false;
    end if;
    # Validar que la carrera exista
    if (select count(*) from carrera where id_carrera = p_carrera) = 0 then
          signal sqlstate '45000' set message_text = 'La carrera no existe';
    end if;
    # Validar que el curso no exista
    if (select count(*) from curso where codigo = p_codigo) > 0 then
        signal sqlstate '45000' set message_text = 'El curso ya existe';
    end if;
    # creditos necesarios debe ser >= 0
    if p_creditos_necesarios < 0 then
        signal sqlstate '45000' set message_text = 'Los creditos necesarios deben ser mayor o igual a 0';
    end if;
    # creditos obtenidos debe ser >= 0
    if p_creditos_obtenidos < 0 then
        signal sqlstate '45000' set message_text = 'Los creditos obtenidos deben ser mayor o igual a 0';
    end if;
    start transaction;
    insert into curso values(p_codigo, p_nombre, p_creditos_necesarios, p_creditos_obtenidos, p_carrera, v_obligatorio);
    commit;
    select 'Curso registrado exitosamente' as resultado;
end //

####Registrar curso habilitado
Delimiter //
create procedure habilitarCurso(
    p_codigo_curso bigint,
    p_ciclo enum('1S', '2S', 'VJ', 'VD'),
    p_docente_siif bigint,
    p_cupo_maximo int,
    p_seccion char(1)
)
begin

    # Validar que el curso exista
    if not curso_existe(p_codigo_curso) then
        signal sqlstate '45000' set message_text = 'El curso no existe';
    end if;
    # ciclo debe ser 1S, 2S, VJ o VD
    if p_ciclo not in ('1S', '2S', 'VJ', 'VD') then
        signal sqlstate '45000' set message_text = 'El ciclo debe ser 1S, 2S, VJ o VD';
    end if;
    # Validar que el docente exista
    if not docente_existe(p_docente_siif) then
        signal sqlstate '45000' set message_text = 'El docente no existe';
    end if;
    # cupo maximo debe ser > 0
    if p_cupo_maximo <= 0 then
        signal sqlstate '45000' set message_text = 'El cupo maximo debe ser mayor a 0';
    end if;
    # secccion debe ser una letra y mayuscula
    if not (p_seccion between 'A' and 'Z') then
        signal sqlstate '45000' set message_text = 'La seccion debe ser una letra mayuscula';
    end if;
    # Validar que no exista una habilitacion para el curso en el ciclo y seccion indicados
    if curso_habilitado_existe_ciclo_seccion_anio(p_codigo_curso, p_ciclo, p_seccion) then
        signal sqlstate '45000' set message_text = 'Ya existe una habilitacion para el curso en el ciclo y seccion indicados';
    end if;
    
    start transaction;
    insert into curso_habilitado(codigo_curso, ciclo, docente_siif, cupo_maximo, seccion) values(p_codigo_curso, p_ciclo, p_docente_siif, p_cupo_maximo, p_seccion);
    commit;
end //

####Agregar horario
Delimiter //
create procedure agregarHorario(
    p_id_habilitacion bigint,
    p_dia tinyint,
    p_horario varchar(50)
)
begin

    # Validar que la habilitacion exista
    if not curso_habilitado_existe(p_id_habilitacion) then
        signal sqlstate '45000' set message_text = 'La habilitacion no existe';
    end if;
    # dia debe ser entre 1 y 7
    if not (p_dia between 1 and 7) then
        signal sqlstate '45000' set message_text = 'El dia debe ser entre 1 y 7';
    end if;
    start transaction;
    insert into horario(id_habilitacion, dia, horario) values(p_id_habilitacion, p_dia, p_horario);
    commit;
end //

####Asignar curso
Delimiter //
create procedure asignarCurso(
    p_codigo_curso bigint,
    p_ciclo enum('1S', '2S', 'VJ', 'VD'),
    p_seccion char(1),
    p_carnet_estudiante bigint
)
begin
    declare v_id_habilitacion bigint;


    # Validar que el curso exista
    if not curso_existe(p_codigo_curso) then
        signal sqlstate '45000' set message_text = 'El curso no existe';
    end if;
    # ciclo debe ser 1S, 2S, VJ o VD
    if p_ciclo not in ('1S', '2S', 'VJ', 'VD') then
        signal sqlstate '45000' set message_text = 'El ciclo debe ser 1S, 2S, VJ o VD';
    end if;
    # secccion debe ser una letra y mayuscula
    if not (p_seccion between 'A' and 'Z') then
        signal sqlstate '45000' set message_text = 'La seccion debe ser una letra mayuscula';
    end if;
    # Validar que el estudiante exista
    if (select count(*) from estudiante where carnet = p_carnet_estudiante) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no existe';
    end if;
    # Debe existir el curso habilitado
    if not curso_habilitado_existe_ciclo_seccion_anio(p_codigo_curso, p_ciclo, p_seccion) then
        signal sqlstate '45000' set message_text = 'No existe una habilitacion para el curso en el ciclo y seccion indicados';
    end if;    
    
    set v_id_habilitacion = (select id_habilitacion from curso_habilitado where codigo_curso = p_codigo_curso and ciclo = p_ciclo and seccion = p_seccion and anio = 2023);

    # Validar que el estudiante no tenga el curso asignado
    if (select count(*) from asignacion where id_habilitacion = v_id_habilitacion and carnet_estudiante = p_carnet_estudiante and fecha_desasignacion is null) > 0 then
        signal sqlstate '45000' set message_text = 'El estudiante ya tiene el curso asignado';
    end if;

    # Debe pertenecer a la carrera o area comun id_carrera = 1
    if (
        select 
            count(*)
        from 
            estudiante e
            inner join curso c on (c.codigo = p_codigo_curso) and (e.carrera = c.carrera or c.carrera = 1)
        where 
            e.carnet = p_carnet_estudiante
        ) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no pertenece a la carrera o area comun del curso';
    end if;
    

    # Debe contar con los creditos necesarios
    if (
        select 
            count(*)
        from 
            estudiante e
            inner join curso c on c.codigo = p_codigo_curso
        where 
            e.carnet = p_carnet_estudiante  and
            e.creditos_obtenidos >= c.creditos_necesarios
        ) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no cuenta con los creditos necesarios';
    end if;

    # No se hay alcanzado el cupo maximo
    if (
        select 
            count(*)
        from 
            curso_habilitado ch
        where 
            ch.id_habilitacion = v_id_habilitacion and
            ch.cupo_actual < ch.cupo_maximo
        ) = 0 then
        signal sqlstate '45000' set message_text = 'Se ha alcanzado el cupo maximo';
    end if;

    start transaction;
    insert into asignacion(id_habilitacion, carnet_estudiante) values(v_id_habilitacion, p_carnet_estudiante);
    commit;
end //

####Desasignar curso
Delimiter //
create procedure desasignarCurso(
    p_codigo_curso bigint,
    p_ciclo enum('1S', '2S', 'VJ', 'VD'),
    p_seccion char(1),
    p_carnet_estudiante bigint
)
begin
    declare v_id_habilitacion bigint;


    # Validar que el curso exista
    if not curso_existe(p_codigo_curso) then
        signal sqlstate '45000' set message_text = 'El curso no existe';
    end if;
    # ciclo debe ser 1S, 2S, VJ o VD
    if p_ciclo not in ('1S', '2S', 'VJ', 'VD') then
        signal sqlstate '45000' set message_text = 'El ciclo debe ser 1S, 2S, VJ o VD';
    end if;
    # secccion debe ser una letra y mayuscula
    if not (p_seccion between 'A' and 'Z') then
        signal sqlstate '45000' set message_text = 'La seccion debe ser una letra mayuscula';
    end if;
    # Validar que el estudiante exista
    if (select count(*) from estudiante where carnet = p_carnet_estudiante) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no existe';
    end if;
    # Debe existir el curso habilitado
    if not curso_habilitado_existe_ciclo_seccion_anio(p_codigo_curso, p_ciclo, p_seccion) then
        signal sqlstate '45000' set message_text = 'No existe una habilitacion para el curso en el ciclo y seccion indicados';
    end if;    
    
    set v_id_habilitacion = (select id_habilitacion from curso_habilitado where codigo_curso = p_codigo_curso and ciclo = p_ciclo and seccion = p_seccion and anio = 2023);

    # Validar que el estudiante tenga el curso asignado
    if (select count(*) from asignacion where id_habilitacion = v_id_habilitacion and carnet_estudiante = p_carnet_estudiante and fecha_desasignacion is null) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no tiene el curso asignado';
    end if;

    start transaction;
    update asignacion set fecha_desasignacion = now() where id_habilitacion = v_id_habilitacion and carnet_estudiante = p_carnet_estudiante and fecha_desasignacion is null;
    commit;
end //

####Registrar nota
Delimiter //
create procedure registrarNota(
    p_codigo_curso bigint,
    p_ciclo enum('1S', '2S', 'VJ', 'VD'),
    p_seccion char(1),
    p_carnet_estudiante bigint,
    p_nota decimal(5,2)
)
begin
    declare v_id_habilitacion bigint;
    declare v_id_asignacion bigint;


    # Validar que el curso exista
    if not curso_existe(p_codigo_curso) then
        signal sqlstate '45000' set message_text = 'El curso no existe';
    end if;
    # ciclo debe ser 1S, 2S, VJ o VD
    if p_ciclo not in ('1S', '2S', 'VJ', 'VD') then
        signal sqlstate '45000' set message_text = 'El ciclo debe ser 1S, 2S, VJ o VD';
    end if;
    # secccion debe ser una letra y mayuscula
    if not (p_seccion between 'A' and 'Z') then
        signal sqlstate '45000' set message_text = 'La seccion debe ser una letra mayuscula';
    end if;
    # Validar que el estudiante exista
    if (select count(*) from estudiante where carnet = p_carnet_estudiante) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no existe';
    end if;
    # Debe existir el curso habilitado
    if not curso_habilitado_existe_ciclo_seccion_anio(p_codigo_curso, p_ciclo, p_seccion) then
        signal sqlstate '45000' set message_text = 'No existe una habilitacion para el curso en el ciclo y seccion indicados';
    end if;    
    
    set v_id_habilitacion = (select id_habilitacion from curso_habilitado where codigo_curso = p_codigo_curso and ciclo = p_ciclo and seccion = p_seccion and anio = 2023);

    # Validar que el estudiante tenga el curso asignado
    if (select count(*) from asignacion where id_habilitacion = v_id_habilitacion and carnet_estudiante = p_carnet_estudiante and fecha_desasignacion is null) = 0 then
        signal sqlstate '45000' set message_text = 'El estudiante no tiene el curso asignado';
    end if;

    set v_id_asignacion = (select id_asignacion from asignacion where id_habilitacion = v_id_habilitacion and carnet_estudiante = p_carnet_estudiante and fecha_desasignacion is null);

    # Validar que la nota sea sea entre 0 y 100
    if not (p_nota between 0 and 100) then
        signal sqlstate '45000' set message_text = 'La nota debe ser entre 0 y 100';
    end if;

    start transaction;
    insert into nota(id_asignacion, nota) values(v_id_asignacion, p_nota);
    commit;
    select 'Nota registrada exitosamente' as resultado;
end //

####Registrar acta
Delimiter //
create procedure registrarActa(
    p_codigo_curso bigint,
    p_ciclo enum('1S', '2S', 'VJ', 'VD'),
    p_seccion char(1)
)
begin
    declare v_id_habilitacion bigint;


    # Validar que el curso exista
    if not curso_existe(p_codigo_curso) then
        signal sqlstate '45000' set message_text = 'El curso no existe';
    end if;
    # ciclo debe ser 1S, 2S, VJ o VD
    if p_ciclo not in ('1S', '2S', 'VJ', 'VD') then
        signal sqlstate '45000' set message_text = 'El ciclo debe ser 1S, 2S, VJ o VD';
    end if;
    # secccion debe ser una letra y mayuscula
    if not (p_seccion between 'A' and 'Z') then
        signal sqlstate '45000' set message_text = 'La seccion debe ser una letra mayuscula';
    end if;
    # Debe existir el curso habilitado
    if not curso_habilitado_existe_ciclo_seccion_anio(p_codigo_curso, p_ciclo, p_seccion) then
        signal sqlstate '45000' set message_text = 'No existe una habilitacion para el curso en el ciclo y seccion indicados';
    end if;    
    
    set v_id_habilitacion = (select id_habilitacion from curso_habilitado where codigo_curso = p_codigo_curso and ciclo = p_ciclo and seccion = p_seccion and anio = 2023);

    # Deben haber la misma cantidad de notas que de asignaciones
    if (
        select 
            count(*)
        from 
            asignacion a
            inner join nota n on n.id_asignacion = a.id_asignacion and a.fecha_desasignacion is null
        where 
            a.id_habilitacion = v_id_habilitacion
        ) != (
        select 
            count(*)
        from 
            asignacion a
        where 
            a.id_habilitacion = v_id_habilitacion and a.fecha_desasignacion is null
        ) then
        signal sqlstate '45000' set message_text = 'No se han registrado todas las notas';
    end if;

    start transaction;
    insert into acta(id_habilitacion, fecha) values(v_id_habilitacion, now());
    commit;
end //


### triggers

#### al registrar una nota, actualizar creditos obtenidos del estudiante en la entidad del estudiante si la nota redondeada al entero mas proximo es >= 61
Delimiter //
create trigger actualizar_creditos_obtenidos after insert on nota
for each row
begin
    -- verificar que la nota sea >= 61
    if round(new.nota) >= 61 then
        update 
            estudiante
        set
         creditos_obtenidos = 
         creditos_obtenidos
          + 
          (
            select
             c.creditos_obtenidos 
            from asignacion a
            inner join curso_habilitado ch on ch.id_habilitacion = a.id_habilitacion
            inner join curso c on c.codigo = ch.codigo_curso
            where a.id_asignacion = new.id_asignacion
            )
        where carnet = (
            select carnet_estudiante from asignacion where id_asignacion = new.id_asignacion
        );
    end if;
end //

### Al haber una inserción o modificacion en la tabla asignacion, actualizar el cupo actual de la habilitacion
Delimiter //
create trigger actualizar_cupo_actual after insert on asignacion
for each row
begin
    update 
        curso_habilitado
    set
        cupo_actual = cupo_actual + 1
    where id_habilitacion = new.id_habilitacion;
end //

### Al haber una desasignacion, actualizar el cupo actual de la habilitacion
Delimiter //
create trigger actualizar_cupo_actual_desasignacion after update on asignacion
for each row
begin
    if new.fecha_desasignacion is not null then
        update 
            curso_habilitado
        set
            cupo_actual = cupo_actual - 1
        where id_habilitacion = new.id_habilitacion;
    end if;
end //

#### Trigers para el historial de transacciones

# carrera - insert
Delimiter //
create trigger historial_transacciones_insert_carrera after insert on carrera
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado la carrera ', new.nombre), 'insert');
end //

# carrera - update
Delimiter //
create trigger historial_transacciones_update_carrera after update on carrera
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado la carrera ', new. nombre), 'update');
end //

# carrera - delete
Delimiter //
create trigger historial_transacciones_delete_carrera after delete on carrera
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado la carrera ', OLD.nombre), 'delete');
end //

# docente - insert
Delimiter //
create trigger historial_transacciones_insert_docente after insert on docente
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado el docente ', new.siif), 'insert');
end //

# docente - update
Delimiter //
create trigger historial_transacciones_update_docente after update on docente
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado el docente ', new.siif), 'update');
end //

# docente - delete
Delimiter //
create trigger historial_transacciones_delete_docente after delete on docente
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado el docente ', old.siif), 'delete');
end //

# estudiante - insert
Delimiter //
create trigger historial_transacciones_insert_estudiante after insert on estudiante
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado el estudiante ', new.carnet), 'insert');
end //

# estudiante - update
Delimiter //
create trigger historial_transacciones_update_estudiante after update on estudiante
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado el estudiante ', new.carnet), 'update');
end //

# estudiante - delete
Delimiter //
create trigger historial_transacciones_delete_estudiante after delete on estudiante
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado el estudiante ', old.carnet), 'delete');
end //

# curso - insert
Delimiter //
create trigger historial_transacciones_insert_curso after insert on curso
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado el curso ', new.nombre), 'insert');
end //

# curso - update
Delimiter //
create trigger historial_transacciones_update_curso after update on curso
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado el curso ', new.nombre), 'update');
end //

# curso - delete
Delimiter //
create trigger historial_transacciones_delete_curso after delete on curso
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado el curso ', old.nombre), 'delete');
end //

# curso_habilitado - insert
Delimiter //
create trigger historial_transacciones_insert_curso_habilitado after insert on curso_habilitado
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado el curso habilitado ', new.id_habilitacion), 'insert');
end //

# curso_habilitado - update
Delimiter //
create trigger historial_transacciones_update_curso_habilitado after update on curso_habilitado
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado el curso habilitado ', new.id_habilitacion), 'update');
end //

# curso_habilitado - delete
Delimiter //
create trigger historial_transacciones_delete_curso_habilitado after delete on curso_habilitado
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado el curso habilitado ', old.id_habilitacion), 'delete');
end //

# horario - insert
Delimiter //
create trigger historial_transacciones_insert_horario after insert on horario
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado el horario ', new.id_horario), 'insert');
end //

# horario - update
Delimiter //
create trigger historial_transacciones_update_horario after update on horario
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado el horario ', new.id_horario), 'update');
end //

# horario - delete
Delimiter //
create trigger historial_transacciones_delete_horario after delete on horario
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado el horario ', old.id_horario), 'delete');
end //

# asignacion - insert
Delimiter //
create trigger historial_transacciones_insert_asignacion after insert on asignacion
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado la asignacion ', new.id_asignacion), 'insert');
end //

# asignacion - update
Delimiter //
create trigger historial_transacciones_update_asignacion after update on asignacion
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado la asignacion ', new.id_asignacion), 'update');
end //

# asignacion - delete
Delimiter //
create trigger historial_transacciones_delete_asignacion after delete on asignacion
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado la asignacion ', old.id_asignacion), 'delete');
end //

# nota - insert
Delimiter //
create trigger historial_transacciones_insert_nota after insert on nota
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado la nota ', new.id_nota), 'insert');
end //

# nota - update
Delimiter //
create trigger historial_transacciones_update_nota after update on nota
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado la nota ', new.id_nota), 'update');
end //

# nota - delete
Delimiter //
create trigger historial_transacciones_delete_nota after delete on nota
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado la nota ', old.id_nota), 'delete');
end //

# acta - insert
Delimiter //
create trigger historial_transacciones_insert_acta after insert on acta
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha registrado el acta ', new.id_acta), 'insert');
end //

# acta - update
Delimiter //
create trigger historial_transacciones_update_acta after update on acta
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha actualizado el acta ', new.id_acta), 'update');
end //

# acta - delete
Delimiter //
create trigger historial_transacciones_delete_acta after delete on acta
for each row
begin
    insert into historial_transaccion values(now(), concat('Se ha eliminado el acta ', old.id_acta), 'delete');
end //

#### Reportes

# consultar pensum
DELIMITER //
create procedure consultarPensum(p_carrera bigint)
begin
    select
        c.codigo,
        c.nombre,
        c.creditos_necesarios,
        if (c.obligatorio, 'Si', 'No') as obligatorio
    from
        curso c
    where
        c.carrera = p_carrera or c.carrera = 1
    order by c.codigo;
end //

# consultar estudiante
DELIMITER //
create procedure consultarEstudiante(p_carnet bigint)
begin
    select
        e.carnet,
        concat(e.nombres, ' ', e.apellidos) as nombre_completo,
        e.fecha_nacimiento,
        e.correo,
        e.telefono,
        e.direccion,
        e.cui,
        c.nombre as carrera,
        e.creditos_obtenidos
    from
        estudiante e
        inner join carrera c on c.id_carrera = e.carrera
    where
        e.carnet = p_carnet;
end //

# consultar docente


DELIMITER //
create procedure consultarDocente(p_siif bigint)
begin
    select
        d.siif,
        concat(d.nombres, ' ', d.apellidos) as nombre_completo,
        d.fecha_nacimiento,
        d.correo,
        d.telefono,
        d.direccion,
        d.cui
    from
        docente d
    where
        d.siif = p_siif;
end //

# consultar estudiantes asignados
DELIMITER //
create procedure consultarAsignados(p_codigo_curso bigint, p_ciclo enum('1S', '2S', 'VJ', 'VD'), p_anio int, p_seccion char(1))
begin
    select
        e.carnet,
        concat(e.nombres, ' ', e.apellidos) as nombre_completo,
        e.creditos_obtenidos
    from
        asignacion a
        inner join estudiante e on e.carnet = a.carnet_estudiante
        inner join curso_habilitado ch on ch.id_habilitacion = a.id_habilitacion
    where
        ch.codigo_curso = p_codigo_curso and
        ch.ciclo = p_ciclo and
        ch.anio = p_anio and
        ch.seccion = p_seccion and
        a.fecha_desasignacion is null;
end //

# consultar aprobaciones
DELIMITER //
create procedure consultarAprobacion(p_codigo_curso bigint, p_ciclo enum('1S', '2S', 'VJ', 'VD'), p_anio int, p_seccion char(1))
begin
    select
        ch.codigo_curso,
        e.carnet,
        concat(e.nombres, ' ', e.apellidos) as nombre_completo,
        if (round(n.nota) >= 61, 'Aprobado', 'Desaprobado') as aprobado
    from
        asignacion a
        inner join estudiante e on e.carnet = a.carnet_estudiante
        inner join curso_habilitado ch on ch.id_habilitacion = a.id_habilitacion
        inner join nota n on n.id_asignacion = a.id_asignacion
    where
        ch.codigo_curso = p_codigo_curso and
        ch.ciclo = p_ciclo and
        ch.anio = p_anio and
        ch.seccion = p_seccion and
        a.fecha_desasignacion is null;
end //


# consultarActas
DELIMITER //
create procedure consultarActas(p_codigo_curso bigint)
begin
    select
        ch.codigo_curso,
        ch.seccion,
        if (ch.ciclo = '1S', 'Primer Semestre', if (ch.ciclo = '2S', 'Segundo Semestre', if (ch.ciclo = 'VJ', 'Vacaciones de Julio', 'Vacaciones de Diciembre'))) as ciclo,
        ch.anio,
        ch.cupo_actual,
        a.fecha
    from acta a
    inner join curso_habilitado ch on ch.id_habilitacion = a.id_habilitacion
    where ch.codigo_curso = p_codigo_curso;
end //

# consultarDesasignacion
DELIMITER //
create procedure consultarDesasignacion(p_codigo_curso bigint, p_ciclo enum('1S', '2S', 'VJ', 'VD'), p_anio int, p_seccion char(1))
begin
    select
        ch.codigo_curso,
        ch.seccion,
        if (ch.ciclo = '1S', 'Primer Semestre', if (ch.ciclo = '2S', 'Segundo Semestre', if (ch.ciclo = 'VJ', 'Vacaciones de Julio', 'Vacaciones de Diciembre'))) as ciclo,
        ch.anio,
        ch.cupo_actual as asignaciones,
        count(*) as desasignaciones,
        count(*) / ch.cupo_actual as tasa_desasignacion
    from asignacion a
    inner join curso_habilitado ch on ch.id_habilitacion = a.id_habilitacion
    where ch.codigo_curso = p_codigo_curso and
        ch.ciclo = p_ciclo and
        ch.anio = p_anio and
        ch.seccion = p_seccion and
        a.fecha_desasignacion is not null
    group by ch.id_habilitacion;
end //

#### datos



#crear carrera
call crearCarrera('Area comun');
call crearCarrera('Ingenieria en Ciencias y Sistemas');
call crearCarrera('Ingenieria Industrial');
call crearCarrera('Ingenieria Mecanica');
call crearCarrera('Ingenieria Quimica');
call crearCarrera('Ingenieria Civil');

#crear docente


call registrarDocente('Juan', 'Perez', '1990-01-01', 'profesor1@universidad.com', '12345678', 'Ciudad', 1234567890101, 1);
call registrarDocente('Pedro', 'Gomez', '1990-01-01','profesor2@universidad.com', '12345607', 'Ciudad', 9234567890101, 2);
call registrarDocente('Maria', 'Lopez', '1990-01-01','profesor3@universidad.com', '12345618', 'Ciudad', 2234567890101, 3);
call registrarDocente('Jose', 'Garcia', '1990-01-01','profesor4@universidad.com', '12345629', 'Ciudad', 3234567890101, 4);
call registrarDocente('Luis', 'Rodriguez', '1990-01-01','profesor5@universidad.com', '12345630', 'Ciudad', 4234567890101, 5);

#crear estudiantes (2 por carrera)
call registrarEstudiante(201900000, 'Estudiante', '1', '2000-01-01','estudiante1@universidad.com', '12345678', 'Ciudad', '1234567890101', 2);
call registrarEstudiante(201900001, 'Estudiante', '2', '2000-01-01','estudiante2@universidad.com', '12345607', 'Ciudad', '9234567890101', 2);
call registrarEstudiante(201900002, 'Estudiante', '3', '2000-01-01','estudiante3@universidad.com', '12345618', 'Ciudad', '2234567890101', 2);
call registrarEstudiante(201900003, 'Estudiante', '4', '2000-01-01','estudiante4@universidad.com', '12335629', 'Ciudad', '3234567890101', 2);
call registrarEstudiante(201900004, 'Estudiante', '5', '2000-01-01','estudiante5@universidad.com', '12325629', 'Ciudad', '3243567890101', 2);
call registrarEstudiante(201900005, 'Estudiante', '6', '2000-01-01','estudiante6@universidad.com', '12315629', 'Ciudad', '3212567890101', 2);
call registrarEstudiante(201900006, 'Estudiante', '7', '2000-01-01','estudiante7@universidad.com', '12325629', 'Ciudad', '3234569090101', 3);
call registrarEstudiante(201900007, 'Estudiante', '8', '2000-01-01','estudiante8@universidad.com', '12345629', 'Ciudad', '3234567812501', 5);
call registrarEstudiante(201900008, 'Estudiante', '9', '2000-01-01','estudiante9@universidad.com', '12345629', 'Ciudad', '3234554890101', 5);
call registrarEstudiante(201900009, 'Estudiante', '10','2000-01-01', 'estudiante10@universidad.com', '12347629', 'Ciudad', '3234534890101', 6);

# 5 cursos por cada carrera y 5 de área común

call crearCurso(1, 'Matematica 1', 0, 2, 1, 1);
call crearCurso(2, 'Matematica 2', 2, 2, 1, 1);
call crearCurso(3, 'Matematica 3', 4, 2, 1, 1);
call crearCurso(4, 'Matematica 4', 6, 2, 1, 1);
call crearCurso(5, 'Matematica 5', 8, 2, 1, 1);

call crearCurso(6, 'IPC 1', 0, 2, 2, 1);
call crearCurso(7, 'IPC 2', 0, 2, 2, 1);
call crearCurso(8, 'IPC 3', 2, 2, 2, 1);
call crearCurso(9, 'IPC 4', 2, 2, 2, 1);
call crearCurso(10, 'IPC 5', 4, 2, 2, 1);

call crearCurso(11, 'IO 1', 0, 2, 3, 1);
call crearCurso(12, 'IO 2', 2, 2, 3, 1);
call crearCurso(13, 'IO 3', 4, 2, 3, 1);
call crearCurso(14, 'IO 4', 6, 2, 3, 1);
call crearCurso(15, 'IO 5', 8, 2, 3, 1);

call crearCurso(16, 'Mecanica 1', 4, 2, 4, 1);
call crearCurso(17, 'Mecanica 2', 6, 2, 4, 1);
call crearCurso(18, 'Mecanica 3', 6, 2, 4, 1);
call crearCurso(19, 'Mecanica 4', 8, 2, 4, 1);
call crearCurso(20, 'Mecanica 5', 8, 2, 4, 1);


call crearCurso(21, 'Quimica 1', 0, 2, 5, 1);
call crearCurso(22, 'Quimica 2', 2, 2, 5, 1);
call crearCurso(23, 'Quimica 3', 4, 2, 5, 1);
call crearCurso(24, 'Quimica 4', 6, 2, 5, 1);
call crearCurso(25, 'Quimica 5', 8, 2, 5, 1);

call crearCurso(26, 'Dibujo 1', 0, 2, 6, 1);
call crearCurso(27, 'Dibujo 2', 2, 2, 6, 1);
call crearCurso(28, 'Dibujo 3', 4, 2, 6, 1);
call crearCurso(29, 'Dibujo 4', 6, 2, 6, 1);
call crearCurso(30, 'Dibujo 5', 8, 2, 6, 1);


# Cursos de area comun
call habilitarCurso(1, '1S', 1, 5, 'A'); # Matematica 1 A
call habilitarCurso(2, '1S', 1, 5, 'A'); # Matematica 2 A
call habilitarCurso(3, '1S', 1, 5, 'A'); # Matematica 3 A
call habilitarCurso(4, '1S', 1, 5, 'A'); # Matematica 4 A
call habilitarCurso(5, '1S', 1, 5, 'A'); # Matematica 5 A

# cursos de sistemas
call habilitarCurso(6, '1S', 1, 4, 'A'); # IPC 1 A
call habilitarCurso(6, '1S', 1, 4, 'B'); # IPC 1 B

call habilitarCurso(7, '1S', 1, 4, 'A'); # IPC 2 A
call habilitarCurso(8, '1S', 1, 4, 'A'); # IPC 3 A
call habilitarCurso(9, '1S', 1, 4, 'A'); # IPC 4 A
call habilitarCurso(10, '1S', 1, 4, 'A'); # IPC 5 A

# Creando algunos horarios
call agregarHorario(1, 1, '09:00');
call agregarHorario(1, 1, '09:00');

# Asignando a algunos estudiantes

# estudiante de sistemas asignado a MB1
call asignarCurso(1, '1S', 'A', 201900000);
call asignarCurso(1, '1S', 'A', 201900001);
call asignarCurso(1, '1S', 'A', 201900002);
call asignarCurso(1, '1S', 'A', 201900003);
call asignarCurso(1, '1S', 'A', 201900004);

# error por cupo maximo
#call asignarCurso(1, '1S', 'A', 201900005);

# se desasigna un estudiante
call desasignarCurso(1, '1S', 'A', 201900004);

# asignar notas
call registrarNota(1, '1S', 'A', 201900000, 100);
call registrarNota(1, '1S', 'A', 201900001, 60);
call registrarNota(1, '1S', 'A', 201900002, 59);
call registrarNota(1, '1S', 'A', 201900003, 80);

# reportes
call consultarPensum(2);
call consultarEstudiante(201900000);
call consultarDocente(1);
call consultarAsignados(1, '1S', 2023, 'A');
call consultarAprobacion(1, '1S', 2023, 'A');
call consultarActas(1);
call consultarTasaDesasignacion(1, '1S', 2023, 'A');
#call consultarDesasignacion(1, '1S', 2023, 'A');

select *
from historial_transaccion;
