# Control de Licencias de Software

App para que RR.HH. (y managers de área con permisos limitados) controlen
qué licencias de software tiene la empresa y a quién están asignadas.

Stack: **Next.js 14 (App Router) + Supabase (Postgres/Auth/RLS) + Vercel**,
en línea con tus otros proyectos.

## Funcionalidades

- **Panel**: licencias activas, seats ocupados/libres, costo mensual estimado,
  licencias por vencer en 30 días, últimas asignaciones.
- **Licencias**: catálogo de licencias compradas (nombre, proveedor, costo,
  periodicidad, seats totales, vencimiento). Alta/edición solo RR.HH.
- **Empleados**: alta y edición de empleados. RR.HH. ve y edita todos;
  managers solo los de su área.
- **Asignaciones**: asignar una licencia a un empleado y liberarla cuando
  corresponda. El historial queda registrado (fecha de asignación y de
  liberación), no se borra nada.
- **Reportes**: costo mensual por área y por proveedor, tabla completa de
  asignaciones y exportación a CSV.

## Roles

- **rrhh**: acceso total a todo (empleados, licencias, asignaciones de
  cualquier área).
- **manager**: solo ve y gestiona empleados/asignaciones de **su propia
  área**; el catálogo de licencias lo ve en modo lectura.

Los roles y permisos están reforzados con **Row Level Security** en la base
(`supabase/schema.sql`), no solo en el frontend.

## Puesta en marcha

### 1. Crear el proyecto en Supabase

1. Andá a [supabase.com](https://supabase.com) y creá un proyecto nuevo.
2. En **SQL Editor**, pegá y ejecutá todo el contenido de
   `supabase/schema.sql`. Esto crea las tablas, la vista de ocupación y las
   políticas de RLS.
3. En **Authentication → Providers**, dejá habilitado "Email" (con o sin
   confirmación, como prefieras para tu empresa).

### 2. Variables de entorno

Copiá `.env.example` a `.env.local` y completá con los datos de tu proyecto
(Project Settings → API en Supabase):

```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

### 3. Instalar y correr en local

```bash
npm install
npm run dev
```

Abrí `http://localhost:3000`, registrate con tu email de la empresa. Vas a
entrar como "manager" sin área.

### 4. Convertirte en RR.HH. (admin)

En el SQL Editor de Supabase, corré (una sola vez, con tu email):

```sql
update perfiles set rol = 'rrhh', area = null where email = 'tu-email@empresa.com';
```

A partir de ahí vas a tener acceso total. Para dar de alta un manager,
actualizá su fila en `perfiles` con `rol = 'manager'` y el `area` que le
corresponda (tiene que coincidir con el campo `area` que uses en
`empleados`).

### 5. Deploy a Vercel

Subí el repo a GitHub e importalo en Vercel (como tus otros proyectos),
agregando las mismas dos variables de entorno en Project Settings →
Environment Variables.

## Notas de diseño

- El costo mensual mostrado en el panel y en reportes convierte las
  licencias anuales a su equivalente mensual (costo / 12) y no cuenta las de
  pago único, para que el número sea comparable mes a mes.
- "Liberar" una asignación no la borra: le pone fecha de liberación, así
  queda el historial completo de quién tuvo qué licencia y cuándo.
- Si asignás una licencia sin seats libres, el sistema te avisa pero te deja
  igual continuar (por si compraste seats extra sin actualizar el registro
  todavía).
