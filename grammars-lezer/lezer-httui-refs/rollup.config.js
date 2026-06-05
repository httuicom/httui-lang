import typescript from "@rollup/plugin-typescript";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import dts from "rollup-plugin-dts";

export default [
  // ESM + CJS bundle
  {
    input: "src/index.ts",
    output: [
      { file: "dist/index.js", format: "esm", sourcemap: true },
      { file: "dist/index.cjs", format: "cjs", sourcemap: true },
    ],
    plugins: [nodeResolve(), typescript({ tsconfig: "./tsconfig.json" })],
    external: ["@lezer/lr", "@lezer/common"],
  },
  // Type declarations
  {
    input: "src/index.ts",
    output: { file: "dist/index.d.ts", format: "esm" },
    plugins: [dts()],
    external: ["@lezer/lr", "@lezer/common"],
  },
];
