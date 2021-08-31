export enum AUF {
  none,
  U,
  U2,
  UPrime,
}

export enum PLL {
  Aa,
  Ab,
  H,
  Ga,
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
  [PLL.H]: "H",
  [PLL.Ga]: "Ga",
};

export const pllToAlgorithmString: { [key in PLL]: string } = {
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_a
  [PLL.Aa]: "(x) R' U R' D2 R U' R' D2 R2 (x')",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_b
  [PLL.Ab]: "(x) R D' R U2 R' D R U2 R2 (x')",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#H_Permutation
  [PLL.H]: "M2' U M2' U2 M2' U M2'",
  // Taken from https://www.speedsolving.com/wiki/index.php/PLL#G_Permutation_:_a
  [PLL.Ga]: "(y) R2 U (R' U R' U') R U' R2 (D U' R' U) R D'",
};

export const allAUFs = [AUF.none, AUF.U, AUF.U2, AUF.UPrime];
