import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#12181B",
        slate: {
          950: "#0B1215",
        },
        brand: {
          50: "#EEF5F4",
          100: "#D7E7E4",
          300: "#87B3AB",
          500: "#3E7D72",
          600: "#2F655C",
          700: "#254F48",
        },
        amber: {
          500: "#C4842B",
        },
      },
      fontFamily: {
        sans: ["var(--font-source-sans)", "system-ui", "sans-serif"],
        display: ["var(--font-fraunces)", "serif"],
      },
    },
  },
  plugins: [],
};
export default config;
