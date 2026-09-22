import { createClient, getPerfil } from "@/lib/supabase/server";
import EmpleadosClient from "./EmpleadosClient";

export default async function EmpleadosPage() {
  const supabase = createClient();
  const { perfil } = await getPerfil();

  const { data: empleados } = await supabase
    .from("empleados")
    .select("*")
    .order("apellido");

  return (
    <EmpleadosClient
      empleados={empleados ?? []}
      soloArea={perfil?.rol === "manager" ? perfil.area : null}
    />
  );
}
