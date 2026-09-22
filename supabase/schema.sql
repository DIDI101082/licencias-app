-- ==========================================================
-- Esquema: Control de Licencias de Software
-- Ejecutar en el SQL Editor de Supabase (proyecto nuevo o existente)
-- ==========================================================

-- 1. Perfiles: vincula un usuario de auth.users con un rol y un área
create table if not exists perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  email text not null,
  rol text not null check (rol in ('rrhh', 'manager')) default 'manager',
  area text, -- null para rrhh (ve todas las áreas); requerido para manager
  created_at timestamptz not null default now()
);

-- 2. Empleados de la empresa
create table if not exists empleados (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  apellido text not null,
  email text not null unique,
  area text not null,
  puesto text,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

-- 3. Licencias de software disponibles
create table if not exists licencias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,          -- ej: "Microsoft 365 E3"
  proveedor text not null,       -- ej: "Microsoft"
  tipo text,                     -- ej: "Productividad", "Diseño", "Desarrollo"
  costo_unitario numeric(12,2) not null default 0,
  periodicidad text not null check (periodicidad in ('mensual', 'anual', 'unica')) default 'mensual',
  seats_totales int not null default 1,       -- cupos comprados
  fecha_inicio date,
  fecha_vencimiento date,        -- vencimiento del contrato/renovación
  notas text,
  created_at timestamptz not null default now()
);

-- 4. Asignaciones: qué licencia tiene (o tuvo) cada empleado
create table if not exists asignaciones (
  id uuid primary key default gen_random_uuid(),
  licencia_id uuid not null references licencias(id) on delete cascade,
  empleado_id uuid not null references empleados(id) on delete cascade,
  fecha_asignacion date not null default current_date,
  fecha_liberacion date, -- null = sigue activa
  asignado_por uuid references perfiles(id),
  notas text,
  created_at timestamptz not null default now()
);

create index if not exists idx_asignaciones_licencia on asignaciones(licencia_id);
create index if not exists idx_asignaciones_empleado on asignaciones(empleado_id);
create index if not exists idx_asignaciones_activa on asignaciones(licencia_id) where fecha_liberacion is null;
create index if not exists idx_empleados_area on empleados(area);

-- Vista de conveniencia: seats ocupados por licencia
create or replace view licencias_ocupacion as
select
  l.id as licencia_id,
  l.nombre,
  l.seats_totales,
  count(a.id) filter (where a.fecha_liberacion is null) as seats_ocupados,
  l.seats_totales - count(a.id) filter (where a.fecha_liberacion is null) as seats_libres
from licencias l
left join asignaciones a on a.licencia_id = l.id
group by l.id, l.nombre, l.seats_totales;

-- ==========================================================
-- Row Level Security
-- ==========================================================
alter table perfiles enable row level security;
alter table empleados enable row level security;
alter table licencias enable row level security;
alter table asignaciones enable row level security;

-- Función helper: rol y área del usuario actual
create or replace function mi_rol() returns text
language sql security definer stable as
$$ select rol from perfiles where id = auth.uid() $$;

create or replace function mi_area() returns text
language sql security definer stable as
$$ select area from perfiles where id = auth.uid() $$;

-- perfiles: cada usuario ve su propio perfil; rrhh ve todos
create policy "perfiles_select" on perfiles for select
  using (id = auth.uid() or mi_rol() = 'rrhh');
create policy "perfiles_update_propio" on perfiles for update
  using (id = auth.uid());
create policy "perfiles_rrhh_all" on perfiles for all
  using (mi_rol() = 'rrhh');

-- empleados: rrhh CRUD total; manager lee/escribe solo su área
create policy "empleados_rrhh_all" on empleados for all
  using (mi_rol() = 'rrhh');
create policy "empleados_manager_select" on empleados for select
  using (mi_rol() = 'manager' and area = mi_area());
create policy "empleados_manager_insert" on empleados for insert
  with check (mi_rol() = 'manager' and area = mi_area());
create policy "empleados_manager_update" on empleados for update
  using (mi_rol() = 'manager' and area = mi_area());

-- licencias: rrhh CRUD total; manager solo lectura (catálogo)
create policy "licencias_rrhh_all" on licencias for all
  using (mi_rol() = 'rrhh');
create policy "licencias_manager_select" on licencias for select
  using (mi_rol() = 'manager');

-- asignaciones: rrhh CRUD total; manager CRUD limitado a empleados de su área
create policy "asignaciones_rrhh_all" on asignaciones for all
  using (mi_rol() = 'rrhh');
create policy "asignaciones_manager_select" on asignaciones for select
  using (
    mi_rol() = 'manager'
    and empleado_id in (select id from empleados where area = mi_area())
  );
create policy "asignaciones_manager_insert" on asignaciones for insert
  with check (
    mi_rol() = 'manager'
    and empleado_id in (select id from empleados where area = mi_area())
  );
create policy "asignaciones_manager_update" on asignaciones for update
  using (
    mi_rol() = 'manager'
    and empleado_id in (select id from empleados where area = mi_area())
  );

-- ==========================================================
-- Trigger: crear perfil automáticamente al registrarse
-- (por defecto como 'manager'; RRHH debe promover manualmente al primer admin)
-- ==========================================================
create or replace function crear_perfil_nuevo_usuario()
returns trigger language plpgsql security definer as $$
begin
  insert into perfiles (id, nombre, email, rol)
  values (new.id, coalesce(new.raw_user_meta_data->>'nombre', new.email), new.email, 'manager');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure crear_perfil_nuevo_usuario();

-- ==========================================================
-- IMPORTANTE: después de registrar el primer usuario (vos),
-- corré esto una vez para convertirte en RRHH (admin):
--
--   update perfiles set rol = 'rrhh', area = null where email = 'tu-email@empresa.com';
-- ==========================================================
