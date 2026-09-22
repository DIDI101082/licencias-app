"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [modo, setModo] = useState<"entrar" | "registrarse">("entrar");
  const [error, setError] = useState<string | null>(null);
  const [cargando, setCargando] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setCargando(true);

    const { error } =
      modo === "entrar"
        ? await supabase.auth.signInWithPassword({ email, password })
        : await supabase.auth.signUp({ email, password });

    setCargando(false);

    if (error) {
      setError(error.message);
      return;
    }

    router.push("/");
    router.refresh();
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#F7F6F3] px-6">
      <div className="w-full max-w-sm">
        <h1 className="font-display text-3xl text-ink mb-1">Licencias</h1>
        <p className="text-ink/60 text-sm mb-8">
          Control de licencias de software de la empresa
        </p>

        <form onSubmit={onSubmit} className="card p-6 space-y-4">
          <div>
            <label className="label">Email</label>
            <input
              type="email"
              required
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="nombre@empresa.com"
            />
          </div>
          <div>
            <label className="label">Contraseña</label>
            <input
              type="password"
              required
              minLength={6}
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>

          {error && (
            <p className="text-sm text-red-600 bg-red-50 rounded-md px-3 py-2">
              {error}
            </p>
          )}

          <button type="submit" disabled={cargando} className="btn-primary w-full">
            {cargando
              ? "Un momento…"
              : modo === "entrar"
              ? "Entrar"
              : "Crear cuenta"}
          </button>

          <button
            type="button"
            onClick={() => setModo(modo === "entrar" ? "registrarse" : "entrar")}
            className="text-sm text-brand-600 hover:underline w-full text-center"
          >
            {modo === "entrar"
              ? "¿No tenés cuenta? Registrate"
              : "¿Ya tenés cuenta? Entrá"}
          </button>
        </form>

        {modo === "registrarse" && (
          <p className="text-xs text-ink/50 mt-4">
            Las cuentas nuevas quedan como "manager" sin área asignada. RRHH
            debe asignarles área y, si corresponde, subirlas a rol "rrhh"
            desde Supabase.
          </p>
        )}
      </div>
    </div>
  );
}
