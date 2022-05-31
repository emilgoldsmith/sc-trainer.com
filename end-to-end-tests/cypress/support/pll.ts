export enum AUF {
  none,
  U,
  U2,
  UPrime,
}

export enum PLL {
  Aa,
  Ab,
  E,
  H,
  Jb,
  Ua,
  Ga,
  Gb,
  Gc,
  V,
  Z,
}

export const aufToAlgorithmString: { [key in AUF]: string } = {
  [AUF.none]: "",
  [AUF.U]: "U",
  [AUF.U2]: "U2",
  [AUF.UPrime]: "U'",
};

export const pllToPllLetters: { [key in PLL]: string } = {
  [PLL.Aa]: "Aa",
  [PLL.Ab]: "Ab",
  [PLL.E]: "E",
  [PLL.H]: "H",
  [PLL.Jb]: "Jb",
  [PLL.Ua]: "Ua",
  [PLL.Ga]: "Ga",
  [PLL.Gb]: "Gb",
  [PLL.Gc]: "Gc",
  [PLL.V]: "V",
  [PLL.Z]: "Z",
};

// All these algorithms are verified to have the same AUFs as
// the ones the app use through a test in support-tests
export const pllToAlgorithmString: { [key in PLL]: string } = {
  [PLL.Aa]: "(x) R' U R' D2 R U' R' D2 R2 (x')",
  [PLL.Ab]: "(x) R D' R U2 R' D R U2 R2 (x')",
  [PLL.E]: "D R' D2 F' D L D' F D2 R D' F' L' F",
  [PLL.H]: "M2' U M2' U2 M2' U M2'",
  [PLL.Jb]: "B2 (L U L') B2 (R D' R D) R2",
  [PLL.Ua]: "F2 U' (L R') F2 (L' R) U' F2",
  [PLL.Ga]: "F2' D (R' U R' U' R) D' F2 L' U L",
  [PLL.Gb]: "R' U' R B2 D (L' U L U' L) D' B2",
  [PLL.Gc]: "R2' D' F U' F U F' D R2 B U' B'",
  [PLL.V]: "R' U R' U' B' R' B2 U' B' U B' R B R",
  [PLL.Z]: "M2 U2 M U' M2 U' M2 U' M",
};

export const allAUFs = [AUF.none, AUF.U, AUF.U2, AUF.UPrime];
