import os
import re
import textwrap
from pathlib import Path
import pandas as pd
from PIL import Image, ImageDraw, ImageFont


# ╔══════════════════════════════════════════════════════════════╗
# ║                 CONFIGURACION - EDITA ACA                   ║
# ║  Cambia estos valores para ajustar como se generan las      ║
# ║  cartas. No hace falta tocar nada mas abajo.                ║
# ╚══════════════════════════════════════════════════════════════╝

BASE_DIR = Path(__file__).resolve().parent

# --- ARCHIVOS DE ENTRADA / SALIDA ---
CSV_CARTAS = BASE_DIR / "Cartas iniciales.xlsx - CARTAS PROTA.csv"
GODOT_PROJECT_DIR = BASE_DIR.parent / "ug-deck"
CARPETA_SALIDA = GODOT_PROJECT_DIR / "assets" / "cards"

# --- PLANTILLAS POR RAREZA ---
TEMPLATES_DIR = BASE_DIR / "templates"
PLANTILLAS_POR_RAREZA = {
    "Desertor":            TEMPLATES_DIR / "marco_desertor.png",
    "Ingresante":          TEMPLATES_DIR / "marco_ingresante.png",
    "Recursante":          TEMPLATES_DIR / "marco_recursante.png",
    "Ayudante de catedra": TEMPLATES_DIR / "marco_ayudante.png",
    "Ingeniero":           TEMPLATES_DIR / "marco_ingeniero.png",
}
PLANTILLA_DEFAULT = TEMPLATES_DIR / "carta_vacia.png"

# --- FUENTES ---
# Podes cambiar la ruta y el tamano de cada fuente por separado.
# Si la fuente no se encuentra, se usa la del sistema como fallback.

FUENTE_ENERGIA   = BASE_DIR / "FONTS" / "AGENCYR.TTF"   # Fuente para el numero de energia
FUENTE_TEXTOS    = "C:/Windows/Fonts/segoeuib.ttf"       # Segoe UI Bold - soporta acentos

# Tamanos de fuente (en pixeles) - ajusta estos valores si el texto queda muy grande o chico
TAMANO_ENERGIA     = 22    # Numero de energia (circulo arriba a la izquierda)
TAMANO_NOMBRE      = 12    # Nombre de la carta (banner de arriba)
TAMANO_EFECTO      = 8.6    # Texto del efecto mecanico

# --- POSICIONES (coordenadas en pixeles) ---
# Ajusta estos valores si el texto queda corrido en tu plantilla.
# Las coordenadas son (x, y) desde la esquina superior izquierda.
# "y" controla la altura: mas bajo = numero mas grande.

POS_ENERGIA = (125, 85)    # Centro del circulo de energia
Y_NOMBRE    = 99          # Altura del nombre en el banner
Y_EFECTO    = 215         # Altura donde empieza el efecto


# --- TEXTO ---
MAX_CARACTERES_EFECTO      = 25   # Caracteres por linea del efecto antes de hacer wrap
ESPACIO_LINEA_EFECTO       = 11.8   # Pixeles entre lineas del efecto

# --- COLORES (R, G, B) ---
COLOR_TEXTO_NOMBRE  = (20, 20, 30)     # Nombre y efecto
COLOR_TEXTO_EFECTO  = (20, 20, 30)     # Efecto mecanico

COLOR_ENERGIA       = (20, 20, 30)     # Numero de energia

# --- MOSTRAR/OCULTAR ELEMENTOS ---
MOSTRAR_RAREZA = False     # True = muestra la rareza abajo, False = la oculta


# ╔══════════════════════════════════════════════════════════════╗
# ║          FIN DE CONFIGURACION - NO TOCAR DE ACA ABAJO       ║
# ╚══════════════════════════════════════════════════════════════╝

os.makedirs(CARPETA_SALIDA, exist_ok=True)


# =========================
# CARGA DE FUENTES
# =========================

def cargar_fuente(ruta, tamano):
    """Intenta cargar una fuente TTF. Si falla, usa Arial del sistema."""
    try:
        return ImageFont.truetype(str(ruta), tamano)
    except Exception:
        # Fallback: intentar con Arial del sistema (soporta acentos)
        try:
            return ImageFont.truetype("C:/Windows/Fonts/arial.ttf", tamano)
        except Exception:
            print(f"  [AVISO] No se pudo cargar la fuente: {ruta}")
            return ImageFont.load_default()


fuente_energia     = cargar_fuente(FUENTE_ENERGIA, TAMANO_ENERGIA)
fuente_nombre      = cargar_fuente(FUENTE_TEXTOS, TAMANO_NOMBRE)
fuente_efecto      = cargar_fuente(FUENTE_TEXTOS, TAMANO_EFECTO)



# =========================
# FUNCIONES DE TEXTO
# =========================

def limpiar_nombre_archivo(texto):
    texto = str(texto).lower()
    texto = texto.replace("a\u0301", "a").replace("e\u0301", "e").replace("i\u0301", "i")
    texto = texto.replace("o\u0301", "o").replace("u\u0301", "u").replace("n\u0303", "n")
    # Tambien reemplazar los caracteres precompuestos
    texto = texto.replace("\u00e1", "a").replace("\u00e9", "e").replace("\u00ed", "i")
    texto = texto.replace("\u00f3", "o").replace("\u00fa", "u").replace("\u00f1", "n")
    texto = re.sub(r"[^a-z0-9]+", "_", texto)
    texto = texto.strip("_")
    return texto


def ruta_res_carta(nombre):
    nombre_archivo = limpiar_nombre_archivo(nombre)
    return f"res://assets/cards/{nombre_archivo}.png"


def texto_centrado(draw, texto, y, fuente, ancho_imagen, color):
    texto = str(texto)
    bbox = draw.textbbox((0, 0), texto, font=fuente)
    ancho_texto = bbox[2] - bbox[0]
    x = (ancho_imagen - ancho_texto) // 2
    draw.text((x, y), texto, font=fuente, fill=color)


def texto_multilinea_centrado(draw, texto, x_centro, y, fuente, color, max_caracteres, espacio_linea):
    texto = str(texto)
    lineas = textwrap.wrap(texto, width=max_caracteres)

    for linea in lineas:
        bbox = draw.textbbox((0, 0), linea, font=fuente)
        ancho_texto = bbox[2] - bbox[0]
        x = x_centro - ancho_texto // 2
        draw.text((x, y), linea, font=fuente, fill=color)
        y += espacio_linea


# =========================
# GENERADOR DE CARTAS
# =========================

def normalizar_rareza(rareza):
    """Normaliza la rareza quitando acentos para que coincida con el diccionario."""
    rareza = str(rareza).strip()
    # Intentar primero con el texto original
    if rareza in PLANTILLAS_POR_RAREZA:
        return rareza
    # Si no, probar sin acentos
    sin_acentos = rareza
    sin_acentos = sin_acentos.replace("\u00e1", "a").replace("\u00e9", "e").replace("\u00ed", "i")
    sin_acentos = sin_acentos.replace("\u00f3", "o").replace("\u00fa", "u").replace("\u00f1", "n")
    if sin_acentos in PLANTILLAS_POR_RAREZA:
        return sin_acentos
    return rareza


def generar_carta(fila):
    nombre = fila["Nombre de la carta"]
    coste = fila["Coste energ\u00eda"]
    efecto = fila["Efecto"]
    rareza = fila["Rareza"]

    # Seleccionar la plantilla correcta segun la rareza
    rareza_normalizada = normalizar_rareza(rareza)
    plantilla = PLANTILLAS_POR_RAREZA.get(rareza_normalizada, PLANTILLA_DEFAULT)
    if not plantilla.exists():
        print(f"  [AVISO] Plantilla no encontrada para rareza '{rareza}': {plantilla.name}")
        plantilla = PLANTILLA_DEFAULT

    carta = Image.open(plantilla).convert("RGBA")
    draw = ImageDraw.Draw(carta)

    ancho, alto = carta.size
    x_centro = ancho // 2

    # --- ENERGIA (circulo arriba a la izquierda) ---
    coste_texto = str(int(coste)) if str(coste).replace(".", "", 1).isdigit() else str(coste)

    bbox = draw.textbbox((0, 0), coste_texto, font=fuente_energia)
    ancho_coste = bbox[2] - bbox[0]
    alto_coste = bbox[3] - bbox[1]

    x_coste = POS_ENERGIA[0] - ancho_coste // 2
    y_coste = POS_ENERGIA[1] - alto_coste // 2

    draw.text((x_coste, y_coste), coste_texto, font=fuente_energia, fill=COLOR_ENERGIA)

    # --- NOMBRE (banner de arriba) ---
    texto_centrado(
        draw=draw,
        texto=nombre,
        y=Y_NOMBRE,
        fuente=fuente_nombre,
        ancho_imagen=ancho,
        color=COLOR_TEXTO_NOMBRE
    )

   

    # --- EFECTO (texto mecanico) ---
    texto_multilinea_centrado(
        draw=draw,
        texto=efecto,
        x_centro=x_centro - 4,
        y=Y_EFECTO,
        fuente=fuente_efecto,
        color=COLOR_TEXTO_EFECTO,
        max_caracteres=MAX_CARACTERES_EFECTO,
        espacio_linea=ESPACIO_LINEA_EFECTO
    )

 

    # --- GUARDAR ---
    nombre_archivo = limpiar_nombre_archivo(nombre)
    salida = os.path.join(CARPETA_SALIDA, f"{nombre_archivo}.png")

    carta.save(salida)
    print(f"  [OK] {nombre} -> {nombre_archivo}.png")


# =========================
# LECTURA DEL CSV
# =========================

def leer_cartas():
    if not CSV_CARTAS.exists():
        raise FileNotFoundError(f"No se encontro el CSV de cartas: {CSV_CARTAS}")

    df = pd.read_csv(CSV_CARTAS, skiprows=1)
    df = df.dropna(how="all")
    df.columns = [col.strip() for col in df.columns]

    return df


# =========================
# PROGRAMA PRINCIPAL
# =========================

def main():
    cartas = leer_cartas()

    print("=" * 50)
    print("  GENERADOR DE CARTAS - UG DECK")
    print("=" * 50)
    print(f"  CSV: {CSV_CARTAS.name}")
    print(f"  Total de cartas: {len(cartas)}")
    print(f"  Salida: {CARPETA_SALIDA}")
    print()

    # Verificar fuentes
    print("  Fuentes:")
    print(f"    Energia:     {Path(FUENTE_ENERGIA).name} ({TAMANO_ENERGIA}px)")
    print(f"    Textos:      {Path(FUENTE_TEXTOS).name} ({TAMANO_NOMBRE}px nombre, {TAMANO_EFECTO}px efecto)")
    print()

    # Verificar plantillas
    plantillas_faltantes = []
    for rareza, ruta in PLANTILLAS_POR_RAREZA.items():
        estado = "OK" if ruta.exists() else "FALTA"
        if not ruta.exists():
            plantillas_faltantes.append(rareza)
        print(f"    [{estado}] {rareza}: {ruta.name}")
    print()

    # Generar cartas
    print("  Generando cartas...")
    generadas = 0
    errores = 0
    for _, fila in cartas.iterrows():
        try:
            generar_carta(fila)
            generadas += 1
        except Exception as e:
            nombre = fila.get("Nombre de la carta", "???")
            print(f"  [ERROR] {nombre}: {e}")
            errores += 1

    print()
    print("=" * 50)
    print(f"  Listo. {generadas} cartas generadas, {errores} errores.")
    print("=" * 50)


if __name__ == "__main__":
    main()
