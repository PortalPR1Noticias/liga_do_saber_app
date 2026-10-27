"""Gera as páginas públicas da Liga do Saber (para a Play Store).

A Política de Privacidade e os Termos vêm de assets/legal, os mesmos textos
que o app mostra, então a página e o app nunca ficam diferentes. Uso:

    python site/gerar_site.py

O resultado fica em site/_publico. O workflow .github/workflows/site.yml
roda este script e publica no GitHub Pages a cada push na main.
"""

import html
import re
import shutil
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SAIDA = RAIZ / "site" / "_publico"

PAGINAS = {
    "index.html": RAIZ / "site" / "index.md",
    "privacidade.html": RAIZ / "assets" / "legal" / "politica_de_privacidade.md",
    "termos.html": RAIZ / "assets" / "legal" / "termos_de_uso.md",
    "excluir-conta.html": RAIZ / "site" / "excluir_conta.md",
}

MODELO = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{titulo}</title>
<link rel="icon" href="emblema.png">
<style>
  :root {{ --azul: #175FAE; --tinta: #0E2152; --fundo: #F4F8FF; }}
  body {{ margin: 0; background: var(--fundo); color: var(--tinta);
         font: 17px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }}
  header {{ background: var(--azul); padding: 16px; text-align: center; }}
  header img {{ height: 72px; }}
  main {{ max-width: 760px; margin: 0 auto; padding: 24px 16px 48px; }}
  h1 {{ font-size: 1.7em; line-height: 1.25; }}
  h2 {{ margin-top: 1.8em; color: var(--azul); }}
  a {{ color: var(--azul); }}
  footer {{ text-align: center; font-size: .9em; padding: 0 16px 32px; }}
</style>
</head>
<body>
<header><a href="index.html"><img src="emblema.png" alt="Liga do Saber"></a></header>
<main>
{corpo}
</main>
<footer><a href="privacidade.html">Privacidade</a> · <a href="termos.html">Termos</a> · <a href="excluir-conta.html">Excluir conta</a></footer>
</body>
</html>
"""


def inline(texto: str) -> str:
    texto = html.escape(texto, quote=False)
    texto = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", texto)
    return re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', texto)


def markdown_para_html(md: str) -> tuple[str, str]:
    """Converte o Markdown simples dos textos (títulos, listas, parágrafos)."""
    partes, lista, titulo = [], None, "Liga do Saber"

    def fecha_lista():
        nonlocal lista
        if lista:
            partes.append(f"</{lista}>")
            lista = None

    for linha in md.splitlines():
        linha = linha.rstrip()
        item = re.match(r"^(-|\d+\.)\s+(.*)", linha)
        if item:
            tipo = "ul" if item.group(1) == "-" else "ol"
            if lista != tipo:
                fecha_lista()
                partes.append(f"<{tipo}>")
                lista = tipo
            partes.append(f"<li>{inline(item.group(2))}</li>")
            continue
        fecha_lista()
        if not linha:
            continue
        cabecalho = re.match(r"^(#{1,3})\s+(.*)", linha)
        if cabecalho:
            n = len(cabecalho.group(1))
            if n == 1:
                titulo = cabecalho.group(2)
            partes.append(f"<h{n}>{inline(cabecalho.group(2))}</h{n}>")
        else:
            partes.append(f"<p>{inline(linha)}</p>")
    fecha_lista()
    return titulo, "\n".join(partes)


def main() -> None:
    shutil.rmtree(SAIDA, ignore_errors=True)
    SAIDA.mkdir(parents=True)
    shutil.copy(RAIZ / "assets" / "brand" / "emblema.png", SAIDA / "emblema.png")
    for nome, origem in PAGINAS.items():
        titulo, corpo = markdown_para_html(origem.read_text(encoding="utf-8"))
        (SAIDA / nome).write_text(MODELO.format(titulo=html.escape(titulo), corpo=corpo), encoding="utf-8")
        print("gerado", SAIDA / nome)


if __name__ == "__main__":
    main()
