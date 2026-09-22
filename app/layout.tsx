import type { Metadata } from "next";
import { Fraunces, Source_Sans_3 } from "next/font/google";
import "./globals.css";
import { getPerfil } from "@/lib/supabase/server";
import Nav from "@/components/Nav";

const fraunces = Fraunces({ subsets: ["latin"], variable: "--font-fraunces" });
const sourceSans = Source_Sans_3({ subsets: ["latin"], variable: "--font-source-sans" });

export const metadata: Metadata = {
  title: "Control de Licencias",
  description: "Gestión de licencias de software de la empresa",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { perfil } = await getPerfil();

  return (
    <html lang="es">
      <body className={`${fraunces.variable} ${sourceSans.variable} font-sans`}>
        {perfil && <Nav nombre={perfil.nombre} rol={perfil.rol} />}
        <main className="mx-auto max-w-6xl px-6 py-8">{children}</main>
      </body>
    </html>
  );
}
