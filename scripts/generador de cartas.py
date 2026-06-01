import os
import re
import textwrap
from pathlib import Path
import pandas as pd
from PIL import Image, ImageDraw, ImageFont, ImageOps


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
CARPETA_ARTE = BASE_DIR / "card_art"

# --- CALIDAD / RESOLUCION ---
FACTOR_ESCALA = 2          # 1 = original (400x400), 2 = doble resolucion (800x800), 3 = triple (1200x1200), etc.
                           # Aumentar este valor mejora drasticamente la nitidez de la ilustracion y las letras.
FILTRO_ARTE = "LANCZOS"    # "NEAREST" (pixel art puro/mosaico), "BILINEAR" o "LANCZOS" (suave/antialiasing de alta calidad)

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
FUENTE_TEXTOS_IT = "C:/Windows/Fonts/segoeuii.ttf"       # Segoe UI Italic - para descripcion flavor

# Tamanos de fuente (en pixeles) - ajusta estos valores si el texto queda muy grande o chico
TAMANO_ENERGIA     = 22    # Numero de energia (circulo arriba a la izquierda)
TAMANO_NOMBRE      = 12    # Nombre de la carta (banner de arriba)
TAMANO_EFECTO      = 8.6   # Texto del efecto mecanico
TAMANO_DESCRIPCION = 8    # Texto de flavor/descripcion (en italica)

# --- POSICIONES (coordenadas en pixeles) ---
# Ajusta estos valores si el texto queda corrido en tu plantilla.
# Las coordenadas son (x, y) desde la esquina superior izquierda.
# "y" controla la altura: mas bajo = numero mas grande.

POS_ENERGIA = (125, 85)    # Centro del circulo de energia
Y_NOMBRE    = 99          # Altura del nombre en el banner
Y_EFECTO    = 215         # Altura donde empieza el efecto
Y_DESCRIPCION = 244        # Altura donde empieza la descripcion

# --- TEXTO ---
MAX_CARACTERES_EFECTO      = 25   # Caracteres por linea del efecto antes de hacer wrap
MAX_CARACTERES_DESCRIPCION = 30   # Caracteres por linea de la descripcion
ESPACIO_LINEA_EFECTO       = 11.8   # Pixeles entre lineas del efecto
ESPACIO_LINEA_DESCRIPCION  = 11   # Pixeles entre lineas de la descripcion

# --- ARTE DE ILUSTRACION ---
ANCHO_ARTE = 200
ALTO_ARTE = 78
POS_ARTE = (96, 122)

# --- COLORES (R, G, B) ---
COLOR_TEXTO_NOMBRE  = (20, 20, 30)     # Nombre y efecto
COLOR_TEXTO_EFECTO  = (20, 20, 30)     # Efecto mecanico
COLOR_DESCRIPCION   = (160, 30, 45)    # Descripcion/flavor text
COLOR_ENERGIA       = (20, 20, 30)     # Numero de energia

# --- MOSTRAR/OCULTAR ELEMENTOS ---
MOSTRAR_RAREZA = False         # True = muestra la rareza abajo, False = la oculta
MOSTRAR_DESCRIPCION = False    # True = muestra la descripcion/flavor text, False = la oculta


# ╔══════════════════════════════════════════════════════════════╗
# ║          FIN DE CONFIGURACION - NO TOCAR DE ACA ABAJO       ║
# ╚══════════════════════════════════════════════════════════════╝

os.makedirs(CARPETA_SALIDA, exist_ok=True)
os.makedirs(CARPETA_ARTE, exist_ok=True)


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


fuente_energia     = cargar_fuente(FUENTE_ENERGIA, int(TAMANO_ENERGIA * FACTOR_ESCALA))
fuente_nombre      = cargar_fuente(FUENTE_TEXTOS, int(TAMANO_NOMBRE * FACTOR_ESCALA))
fuente_efecto      = cargar_fuente(FUENTE_TEXTOS, int(TAMANO_EFECTO * FACTOR_ESCALA))
fuente_descripcion = cargar_fuente(FUENTE_TEXTOS_IT, int(TAMANO_DESCRIPCION * FACTOR_ESCALA))


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
    descripcion = fila["Descripci\u00f3n"]
    rareza = fila["Rareza"]

    # Seleccionar la plantilla correcta segun la rareza
    rareza_normalizada = normalizar_rareza(rareza)
    plantilla = PLANTILLAS_POR_RAREZA.get(rareza_normalizada, PLANTILLA_DEFAULT)
    if not plantilla.exists():
        print(f"  [AVISO] Plantilla no encontrada para rareza '{rareza}': {plantilla.name}")
        plantilla = PLANTILLA_DEFAULT

    nombre_archivo = limpiar_nombre_archivo(nombre)
    
    # Intentar buscar la imagen de arte en la carpeta de arte
    ruta_arte = None
    formatos = [".png", ".jpg", ".jpeg", ".webp"]
    for fmt in formatos:
        p1 = CARPETA_ARTE / f"{nombre_archivo}{fmt}"
        if p1.exists():
            ruta_arte = p1
            break
        p2 = CARPETA_ARTE / f"{nombre}{fmt}"
        if p2.exists():
            ruta_arte = p2
            break

    # Cargar plantilla y redimensionar si hay factor de escala
    base_template = Image.open(plantilla).convert("RGBA")
    
    # Escalar plantilla con NEAREST para que no pierda el estilo pixel art retro
    if FACTOR_ESCALA != 1:
        resample_template = Image.Resampling.NEAREST if hasattr(Image, "Resampling") else Image.NEAREST
        base_template = base_template.resize(
            (base_template.width * FACTOR_ESCALA, base_template.height * FACTOR_ESCALA),
            resample_template
        )

    ancho, alto = base_template.size
    base_canvas = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))

    if ruta_arte:
        try:
            arte = Image.open(ruta_arte).convert("RGBA")
            
            # Seleccionar filtro de redimensionamiento configurado para la reduccion
            if FILTRO_ARTE == "NEAREST":
                down_filter = Image.Resampling.NEAREST if hasattr(Image, "Resampling") else Image.NEAREST
            elif FILTRO_ARTE == "BILINEAR":
                down_filter = Image.Resampling.BILINEAR if hasattr(Image, "Resampling") else Image.BILINEAR
            else:
                down_filter = Image.Resampling.LANCZOS if hasattr(Image, "Resampling") else Image.LANCZOS

            # Dimensiones del arte a escala
            ancho_arte_esc = int(ANCHO_ARTE * FACTOR_ESCALA)
            alto_arte_esc = int(ALTO_ARTE * FACTOR_ESCALA)
            pos_arte_esc = (int(POS_ARTE[0] * FACTOR_ESCALA), int(POS_ARTE[1] * FACTOR_ESCALA))

            # --- ALINEACIÓN DE PÍXELES (Evitar "Mixels" / inconsistencia de resolución) ---
            # 1. Primero encogemos la imagen de la IA al tamaño original de la ventana (200x78)
            #    usando un filtro de alta calidad para fusionar los detalles sin aliasing.
            arte_lowres = arte.resize((ANCHO_ARTE, ALTO_ARTE), down_filter)
            
            # 2. Luego la agrandamos al tamaño escalado (ej. 400x156) usando NEAREST.
            #    Esto hace que los píxeles del dibujo sean bloques limpios del mismo tamaño
            #    que los píxeles del marco de la carta, logrando una densidad homogénea.
            up_filter = Image.Resampling.NEAREST if hasattr(Image, "Resampling") else Image.NEAREST
            arte_redimensionado = arte_lowres.resize((ancho_arte_esc, alto_arte_esc), up_filter)
            
            # Generar mascara para la ventana interna usando floodfill
            # La mascara tendra 255 (blanco) solo en la ventana transparente central
            alpha = base_template.getchannel('A')
            outside_mask = alpha.copy()
            ImageDraw.floodfill(outside_mask, (0, 0), 255)
            mask = ImageOps.invert(outside_mask)
            
            # Crear lienzo temporal con el arte y pegarlo usando la mascara
            temp_canvas = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
            temp_canvas.paste(arte_redimensionado, pos_arte_esc)
            base_canvas.paste(temp_canvas, (0, 0), mask)
            
            print(f"  [ARTE] Integrando imagen de arte: {ruta_arte.name} para '{nombre}'")
        except Exception as e:
            print(f"  [AVISO] Error cargando arte {ruta_arte.name}: {e}")

    # Superponer la plantilla de la carta sobre el lienzo
    carta = Image.alpha_composite(base_canvas, base_template)
    draw = ImageDraw.Draw(carta)

    x_centro = ancho // 2

    # --- ENERGIA (circulo arriba a la izquierda) ---
    coste_texto = str(int(coste)) if str(coste).replace(".", "", 1).isdigit() else str(coste)

    bbox = draw.textbbox((0, 0), coste_texto, font=fuente_energia)
    ancho_coste = bbox[2] - bbox[0]
    alto_coste = bbox[3] - bbox[1]

    x_coste = int(POS_ENERGIA[0] * FACTOR_ESCALA) - ancho_coste // 2
    y_coste = int(POS_ENERGIA[1] * FACTOR_ESCALA) - alto_coste // 2

    draw.text((x_coste, y_coste), coste_texto, font=fuente_energia, fill=COLOR_ENERGIA)

    # --- NOMBRE (banner de arriba) ---
    texto_centrado(
        draw=draw,
        texto=nombre,
        y=int(Y_NOMBRE * FACTOR_ESCALA),
        fuente=fuente_nombre,
        ancho_imagen=ancho,
        color=COLOR_TEXTO_NOMBRE
    )

    # --- EFECTO (texto mecanico) ---
    texto_multilinea_centrado(
        draw=draw,
        texto=efecto,
        x_centro=x_centro - int(4 * FACTOR_ESCALA),
        y=int(Y_EFECTO * FACTOR_ESCALA),
        fuente=fuente_efecto,
        color=COLOR_TEXTO_EFECTO,
        max_caracteres=MAX_CARACTERES_EFECTO,
        espacio_linea=int(ESPACIO_LINEA_EFECTO * FACTOR_ESCALA)
    )

    # --- DESCRIPCION (flavor text en italica) ---
    if MOSTRAR_DESCRIPCION:
        texto_multilinea_centrado(
            draw=draw,
            texto=descripcion,
            x_centro=x_centro,
            y=int(Y_DESCRIPCION * FACTOR_ESCALA),
            fuente=fuente_descripcion,
            color=COLOR_DESCRIPCION,
            max_caracteres=MAX_CARACTERES_DESCRIPCION,
            espacio_linea=int(ESPACIO_LINEA_DESCRIPCION * FACTOR_ESCALA)
        )

    # --- RAREZA (opcional) ---
    if MOSTRAR_RAREZA:
        y_rareza = alto - int(40 * FACTOR_ESCALA)
        texto_centrado(
            draw=draw,
            texto=str(rareza),
            y=y_rareza,
            fuente=fuente_descripcion,
            ancho_imagen=ancho,
            color=(100, 100, 110)
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
    print(f"    Descripcion: {Path(FUENTE_TEXTOS_IT).name} ({TAMANO_DESCRIPCION}px)")
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
