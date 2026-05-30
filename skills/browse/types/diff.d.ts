// Minimal type declarations for `diff` (v7 ships no .d.ts and there is no
// @types/diff for this major). Only the surface browse actually uses.
declare module 'diff' {
  export interface Change {
    value: string;
    added?: boolean;
    removed?: boolean;
    count?: number;
  }
  export function diffLines(
    oldStr: string,
    newStr: string,
    options?: { ignoreWhitespace?: boolean; newlineIsToken?: boolean },
  ): Change[];
}
