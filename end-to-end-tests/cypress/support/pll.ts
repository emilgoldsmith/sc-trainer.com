export enum AUF {
  none,
  U,
  U2,
  UPrime,
}

export const allAUFs = [AUF.none, AUF.U, AUF.U2, AUF.UPrime];

export enum PLL {
  Aa,
  Ab,
  E,
  F,
  Ga,
  Gb,
  Gc,
  Gd,
  H,
  Ja,
  Jb,
  Na,
  Nb,
  Ra,
  Rb,
  T,
  Ua,
  Ub,
  V,
  Y,
  Z,
}

export const aufToAlgorithmString: { [key in AUF]: string } = {
  [AUF.none]: "",
  [AUF.U]: "U",
  [AUF.U2]: "U2",
  [AUF.UPrime]: "U'",
};

export function parseAUFString(str: string): AUF {
  switch (str) {
    case "U":
      return AUF.U;
    case "U2":
      return AUF.U2;
    case "U'":
      return AUF.UPrime;
    case "":
      return AUF.none;
    default:
      throw new Error(`Invalid AUF string: ${str}`);
  }
}

export const pllToPllLetters: { [key in PLL]: string } = {
  [PLL.Aa]: "Aa",
  [PLL.Ab]: "Ab",
  [PLL.E]: "E",
  [PLL.F]: "F",
  [PLL.Ga]: "Ga",
  [PLL.Gb]: "Gb",
  [PLL.Gc]: "Gc",
  [PLL.Gd]: "Gd",
  [PLL.H]: "H",
  [PLL.Ja]: "Ja",
  [PLL.Jb]: "Jb",
  [PLL.Na]: "Na",
  [PLL.Nb]: "Nb",
  [PLL.Ra]: "Ra",
  [PLL.Rb]: "Rb",
  [PLL.T]: "T",
  [PLL.Ua]: "Ua",
  [PLL.Ub]: "Ub",
  [PLL.V]: "V",
  [PLL.Y]: "Y",
  [PLL.Z]: "Z",
};

export function parsePLLString(str: string): PLL {
  switch (str) {
    case "Aa":
      return PLL.Aa;
    case "Ab":
      return PLL.Ab;
    case "E":
      return PLL.E;
    case "F":
      return PLL.F;
    case "Ga":
      return PLL.Ga;
    case "Gb":
      return PLL.Gb;
    case "Gc":
      return PLL.Gc;
    case "Gd":
      return PLL.Gd;
    case "H":
      return PLL.H;
    case "Ja":
      return PLL.Ja;
    case "Jb":
      return PLL.Jb;
    case "Na":
      return PLL.Na;
    case "Nb":
      return PLL.Nb;
    case "Ra":
      return PLL.Ra;
    case "Rb":
      return PLL.Rb;
    case "T":
      return PLL.T;
    case "Ua":
      return PLL.Ua;
    case "Ub":
      return PLL.Ub;
    case "V":
      return PLL.V;
    case "Y":
      return PLL.Y;
    case "Z":
      return PLL.Z;
    default:
      throw new Error(`Invalid PLL string: ${str}`);
  }
}

export const pllToAlgorithmString: { [key in PLL]: string } = {
  [PLL.Aa]: "(x) R' U R' D2 R U' R' D2 R2 (x')",
  [PLL.Ab]: "(x) R D' R U2 R' D R U2 R2 (x')",
  [PLL.E]: "D R' D2 F' D L D' F D2 R D' F' L' F",
  [PLL.F]: "L F R' F' L' F' D2 B' L' B D2 F' R F2",
  [PLL.Ga]: "F2' D (R' U R' U' R) D' F2 L' U L",
  [PLL.Gb]: "R' U' R B2 D (L' U L U' L) D' B2",
  [PLL.Gc]: "R2' D' F U' F U F' D R2 B U' B'",
  [PLL.Gd]: "R U R' F2 D' (L U' L' U L') D F2",
  [PLL.H]: "M2' U M2' U2 M2' U M2'",
  [PLL.Ja]: "B2 R' U' R B2 L' D L' D' L2",
  [PLL.Jb]: "B2 (L U L') B2 (R D' R D) R2",
  [PLL.Na]: "L U' R U2 L' U R' L U' R U2 L' U R'",
  [PLL.Nb]: "R' U L' U2 R U' L R' U L' U2 R U' L",
  [PLL.Ra]: "F2 R' F' U' F' U F R F' U2 F U2 F'",
  [PLL.Rb]: "R2 F R U R U' R' F' R U2 R' U2 R",
  [PLL.T]: "F2 D R2 U' R2 F2 D' L2 U L2",
  [PLL.Ua]: "F2 U' (L R') F2 (L' R) U' F2",
  [PLL.Ub]: "F2 U (R' L) F2 (R L') U F2",
  [PLL.V]: "R' U R' U' B' R' B2 U' B' U B' R B R",
  [PLL.Y]: "F2 D R2 U R2 D' R' U' R F2 R' U R",
  [PLL.Z]: "M2 U2 M U' M2 U' M2 U' M",
};
