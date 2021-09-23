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
  [PLL.Gc]: "Gc",
  [PLL.V]: "V",
  [PLL.Z]: "Z",
};

export const pllToAlgorithmString: { [key in PLL]: string } = {
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_a
  [PLL.Aa]: "(x) R' U R' D2 R U' R' D2 R2 (x')",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_b
  [PLL.Ab]: "(x) R D' R U2 R' D R U2 R2 (x')",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#E_Permutation
  [PLL.E]: "(y x') (R U' R' D) (R U R' D') (R U R' D) (R U' R' D') (x)",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#H_Permutation
  [PLL.H]: "M2' U M2' U2 M2' U M2'",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#J_Permutation_:_b
  [PLL.Jb]: "(y2) R' U L U' R U2' L' U L U2 L'",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#U_Permutation_:_a
  [PLL.Ua]: "R2 U' R' U' R U R U R U' R",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#G_Permutation_:_a
  [PLL.Ga]: "(y) R2 U (R' U R' U') R U' R2 (D U' R' U) R D'",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#G_Permutation_:_c
  [PLL.Gc]: "(y) R2 U' R U' R U R' U R2 D' U R U' R' D",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#V_Permutation
  [PLL.V]: "(y) R U' R U R' D R D' R U' D R2 U R2 D' R2",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#Z_Permutation
  [PLL.Z]: "M2 U2 M U' M2 U' M2 U' M",
};

export const allAUFs = [AUF.none, AUF.U, AUF.U2, AUF.UPrime];
