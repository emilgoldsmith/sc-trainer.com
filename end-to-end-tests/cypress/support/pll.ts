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

export const allPLLs = [
  PLL.Aa,
  PLL.Ab,
  PLL.E,
  PLL.F,
  PLL.Ga,
  PLL.Gb,
  PLL.Gc,
  PLL.Gd,
  PLL.H,
  PLL.Ja,
  PLL.Jb,
  PLL.Na,
  PLL.Nb,
  PLL.Ra,
  PLL.Rb,
  PLL.T,
  PLL.Ua,
  PLL.Ub,
  PLL.V,
  PLL.Y,
  PLL.Z,
];

if (allPLLs.length !== 21) {
  throw new Error("allPLLs is not 21 long, so there must be an error");
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

/**
 * These algorithms are all just chosen as the shortest ones I could find on Algdb,
 * so that there will be minimal computational / time cost when for example typing them
 * into the browser in Cypress tests
 */
export const pllToAlgorithmString: { [key in PLL]: string } = {
  [PLL.Aa]: "Lw' U R' D2 R U' R' D2 R2",
  [PLL.Ab]: "R2 B2 R F R' B2 R F' R",
  [PLL.E]: "L U' R D2 R' U R L' U' L D2 L' U R'",
  [PLL.F]: "M' U2 L F' R U2 Rw' U Rw' R2 U2 R2",
  [PLL.Ga]: "R2 S2 U Lw2 U' Lw2 Uw R2 U' Rw2 F2",
  [PLL.Gb]: "R' Dw' F R2 Uw R' U R U' R Uw' R2",
  [PLL.Gc]: "R2 S2 U' Lw2 U Lw2 Uw' R2 U Rw2 B2",
  [PLL.Gd]: "F2 R2 D' L2 D L2 U' L2 U M2 B2",
  [PLL.H]: "M2 U M2 U2 M2 U M2",
  [PLL.Ja]: "R2 F2 U' F2 D R2 D' R2 U R2",
  [PLL.Jb]: "R L U2 R' U' R U2 L' U R'",
  [PLL.Na]: "L U' R U2 Rw' F M' U' R U2 Rw' F Lw'",
  [PLL.Nb]: "R' U L' U2 R U' M' B Rw' U2 R U' L",
  [PLL.Ra]: "L U2 L' U2 L F' L' U' L U L F L2",
  [PLL.Rb]: "R' U2 R U2 R' F R U R' U' R' F' R2",
  [PLL.T]: "R2 Uw R2 U' R2 F2 D' Rw2 D Rw2",
  [PLL.Ua]: "M2 U M' U2 M U M2",
  [PLL.Ub]: "M2 U' M' U2 M U' M2",
  [PLL.V]: "R' U R' Dw' R' F' R2 U' R' U R' F R F",
  [PLL.Y]: "R' U' R F2 R' U R Dw R2 U' R2 U' R2",
  [PLL.Z]: "M2 Uw M2 Uw' S M2 S'",
};

export const pllToJpermsAlgorithm: { [key in PLL]: string } = {
  [PLL.Ua]: "M2 U M U2 M' U M2",
  [PLL.Ub]: "M2 U' M U2 M' U' M2",
  [PLL.H]: "M2 U M2 U2 M2 U M2",
  [PLL.Z]: "M U M2 U M2 U M U2 M2",
  [PLL.Aa]: "x L2 D2 (L' U' L) D2 (L' U L')",
  [PLL.Ab]: "x (L U' L) D2 (L' U L) D2 L2",
  [PLL.E]: "x' (L' U L D') (L' U' L D) (L' U' L D') (L' U L D)",
  [PLL.T]: "(R U R' U') R' F R2 U' R' U' (R U R') F'",
  [PLL.F]: "R' U' F' (R U R' U') R' F R2 U' R' U' (R U R') U R",
  [PLL.Jb]: "(R U R' F') (R U R' U') R' F R2 U' R'",
  [PLL.Ja]: "x (R2 F R F') R U2 (r' U r) U2",
  [PLL.Ra]: "(R U' R' U') (R U R D) (R' U' R D') (R' U2 R')",
  [PLL.Rb]: "R2 F R (U R U' R') F' R U2 R' U2 R",
  [PLL.Y]: "F (R U' R' U') (R U R') F' (R U R' U') (R' F R F')",
  [PLL.V]: "R U' (R U R') D R D' R (U' D) R2 U R2 D' R2",
  [PLL.Na]: "(R U R' U) (R U R' F' R U R' U' R' F R2 U' R') (U2 R U' R')",
  [PLL.Nb]: "r' D' F (r U' r') F' D (r2 U r' U') (r' F r F')",
  [PLL.Ga]: "R2 U R' U R' U' R U' R2 (U' D) (R' U R) D'",
  [PLL.Gb]: "(R' U' R) (U D') R2 U R' U R U' R U' R2 D",
  [PLL.Gc]: "R2 U' R U' R U R' U R2 (U D') (R U' R') D",
  [PLL.Gd]: "(R U R') (U' D) R2 U' R U' R' U R' U R2 D'",
};
