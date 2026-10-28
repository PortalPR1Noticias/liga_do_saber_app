// Liga do Saber - montagem das Cruzadas da Liga.
//
// Recebe palavras com pista e cruza umas com as outras numa grade, como
// nas palavras cruzadas de revista: cada palavra nova precisa cruzar uma
// que já está na grade, e duas palavras nunca ficam encostadas lado a
// lado (senão formariam "palavras" sem sentido). Fica num arquivo
// separado, sem dependências, para dar para testar fora do Supabase.

export type Direcao = "h" | "v";

export type PalavraCruzada = {
  /// Como a IA escreveu (com acento), para mostrar quando a criança acerta.
  palavra: string;
  /// Só as letras que vão na grade (A a Z, sem acento).
  letras: string;
  pista: string;
  linha: number;
  coluna: number;
  direcao: Direcao;
  numero: number;
};

export type Cruzadas = {
  linhas: number;
  colunas: number;
  palavras: PalavraCruzada[];
};

/// Maior lado da grade, para caber na tela do celular.
export const TAMANHO_MAXIMO = 12;

/// Só letras de A a Z, sem acento (a grade não tem acentos).
export function paraGrade(palavra: string): string {
  return palavra
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toUpperCase()
    .replace(/[^A-Z]/g, "");
}

type Casa = { letra: string; h: boolean; v: boolean };
type Colocada = {
  palavra: string;
  letras: string;
  pista: string;
  linha: number;
  coluna: number;
  direcao: Direcao;
};

const chave = (l: number, c: number) => `${l},${c}`;
const passo = (d: Direcao): [number, number] => (d === "h" ? [0, 1] : [1, 0]);

class Grade {
  casas = new Map<string, Casa>();
  colocadas: Colocada[] = [];
  minL = 0;
  maxL = -1;
  minC = 0;
  maxC = -1;

  casa(l: number, c: number) {
    return this.casas.get(chave(l, c));
  }

  /// Quantas letras a palavra cruza nessa posição, ou -1 se não cabe.
  cruzamentos(letras: string, l0: number, c0: number, d: Direcao): number {
    const [dl, dc] = passo(d);
    const n = letras.length;
    // Nada encostado antes do começo nem depois do fim.
    if (this.casa(l0 - dl, c0 - dc) || this.casa(l0 + dl * n, c0 + dc * n)) {
      return -1;
    }
    const minL = Math.min(this.minL, l0);
    const maxL = Math.max(this.maxL, l0 + dl * (n - 1));
    const minC = Math.min(this.minC, c0);
    const maxC = Math.max(this.maxC, c0 + dc * (n - 1));
    if (maxL - minL + 1 > TAMANHO_MAXIMO || maxC - minC + 1 > TAMANHO_MAXIMO) {
      return -1;
    }
    let cruza = 0;
    for (let k = 0; k < n; k++) {
      const l = l0 + dl * k;
      const c = c0 + dc * k;
      const atual = this.casa(l, c);
      if (atual) {
        if (atual.letra !== letras[k] || atual[d]) return -1;
        cruza++;
      } else if (
        // Casa nova: os vizinhos dos lados precisam estar vazios.
        this.casa(l + dc, c + dl) || this.casa(l - dc, c - dl)
      ) {
        return -1;
      }
    }
    return cruza;
  }

  colocar(p: Omit<Colocada, "linha" | "coluna">, l0: number, c0: number) {
    const [dl, dc] = passo(p.direcao);
    for (let k = 0; k < p.letras.length; k++) {
      const l = l0 + dl * k;
      const c = c0 + dc * k;
      const atual = this.casa(l, c) ?? { letra: p.letras[k], h: false, v: false };
      atual[p.direcao] = true;
      this.casas.set(chave(l, c), atual);
      this.minL = Math.min(this.minL, l);
      this.maxL = Math.max(this.maxL, l);
      this.minC = Math.min(this.minC, c);
      this.maxC = Math.max(this.maxC, c);
    }
    this.colocadas.push({ ...p, linha: l0, coluna: c0 });
  }

  /// Tenta cruzar a palavra com o que já está na grade. Escolhe o lugar
  /// com mais cruzamentos (empate: sorteio).
  encaixar(
    p: { palavra: string; letras: string; pista: string },
    aleatorio: () => number,
  ): boolean {
    let melhores: [number, number, Direcao][] = [];
    let maisCruzamentos = 0;
    for (const [k, casa] of this.casas) {
      const [l, c] = k.split(",").map(Number);
      for (const d of ["h", "v"] as Direcao[]) {
        if (casa[d]) continue;
        const [dl, dc] = passo(d);
        for (let i = 0; i < p.letras.length; i++) {
          if (p.letras[i] !== casa.letra) continue;
          const l0 = l - dl * i;
          const c0 = c - dc * i;
          const cruza = this.cruzamentos(p.letras, l0, c0, d);
          if (cruza <= 0 || cruza < maisCruzamentos) continue;
          if (cruza > maisCruzamentos) {
            maisCruzamentos = cruza;
            melhores = [];
          }
          melhores.push([l0, c0, d]);
        }
      }
    }
    if (melhores.length === 0) return false;
    const [l0, c0, d] = melhores[Math.floor(aleatorio() * melhores.length)];
    this.colocar({ ...p, direcao: d }, l0, c0);
    return true;
  }
}

function embaralhar<T>(lista: T[], aleatorio: () => number): T[] {
  const copia = [...lista];
  for (let i = copia.length - 1; i > 0; i--) {
    const j = Math.floor(aleatorio() * (i + 1));
    [copia[i], copia[j]] = [copia[j], copia[i]];
  }
  return copia;
}

function umaTentativa(
  palavras: { palavra: string; letras: string; pista: string }[],
  aleatorio: () => number,
): Grade {
  const grade = new Grade();
  // A maior no meio; as outras em ordem sorteada, para variar o desenho.
  const [primeira, ...resto] = palavras;
  grade.colocar(
    { ...primeira, direcao: aleatorio() < 0.5 ? "h" : "v" },
    0,
    0,
  );
  let faltam = embaralhar(resto, aleatorio);
  // Uma palavra que não cruzou agora pode cruzar com uma que entrou depois.
  for (let volta = 0; volta < 2 && faltam.length > 0; volta++) {
    faltam = faltam.filter((p) => !grade.encaixar(p, aleatorio));
  }
  return grade;
}

/// Monta as cruzadas com o máximo de palavras que conseguir cruzar,
/// numeradas como na revista (de cima para baixo, da esquerda para a
/// direita). As horizontais vêm primeiro.
export function montarCruzadas(
  entrada: { palavra: string; pista: string }[],
  aleatorio: () => number = Math.random,
  tentativas = 40,
): Cruzadas {
  const vistas = new Set<string>();
  const palavras = entrada
    .map((p) => ({
      palavra: p.palavra.trim().toUpperCase(),
      letras: paraGrade(p.palavra),
      pista: p.pista.trim(),
    }))
    .filter((p) => {
      if (p.letras.length < 3 || p.letras.length > TAMANHO_MAXIMO) return false;
      if (!p.pista || vistas.has(p.letras)) return false;
      vistas.add(p.letras);
      return true;
    })
    .sort((a, b) => b.letras.length - a.letras.length);
  if (palavras.length === 0) return { linhas: 0, colunas: 0, palavras: [] };

  let melhor: Grade | null = null;
  for (let t = 0; t < tentativas; t++) {
    const grade = umaTentativa(palavras, aleatorio);
    const area = (grade.maxL - grade.minL + 1) * (grade.maxC - grade.minC + 1);
    const areaMelhor = melhor
      ? (melhor.maxL - melhor.minL + 1) * (melhor.maxC - melhor.minC + 1)
      : Infinity;
    if (
      !melhor ||
      grade.colocadas.length > melhor.colocadas.length ||
      (grade.colocadas.length === melhor.colocadas.length && area < areaMelhor)
    ) {
      melhor = grade;
    }
    if (melhor.colocadas.length === palavras.length && t >= 10) break;
  }

  const grade = melhor!;
  const colocadas = grade.colocadas.map((p) => ({
    ...p,
    linha: p.linha - grade.minL,
    coluna: p.coluna - grade.minC,
  }));
  const inicios = [...new Set(colocadas.map((p) => chave(p.linha, p.coluna)))]
    .map((k) => k.split(",").map(Number))
    .sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const numero = new Map(inicios.map(([l, c], i) => [chave(l, c), i + 1]));
  const numeradas: PalavraCruzada[] = colocadas
    .map((p) => ({ ...p, numero: numero.get(chave(p.linha, p.coluna))! }))
    .sort((a, b) =>
      (a.direcao === b.direcao ? 0 : a.direcao === "h" ? -1 : 1) ||
      a.numero - b.numero
    );
  return {
    linhas: grade.maxL - grade.minL + 1,
    colunas: grade.maxC - grade.minC + 1,
    palavras: numeradas,
  };
}
