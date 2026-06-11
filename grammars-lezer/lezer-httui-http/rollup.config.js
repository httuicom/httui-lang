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
    // @lezer/highlight must stay external: bundling it would duplicate
    // Tag instances and break tag matching in consumers.
    external: ["@lezer/lr", "@lezer/common", "@lezer/highlight"],
  },
  // Type declarations
  {
    input: "src/index.ts",
    output: { file: "dist/index.d.ts", format: "esm" },
    plugins: [dts()],
    // @lezer/highlight must stay external: bundling it would duplicate
    // Tag instances and break tag matching in consumers.
    external: ["@lezer/lr", "@lezer/common", "@lezer/highlight"],
  },
];
