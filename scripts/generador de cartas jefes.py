import os
import re
import textwrap
from pathlib import Path
import pandas as pd
from PIL import Image, ImageDraw, ImageFont, ImageOps


# ╔══════════════════════════════════════════════════════════════╗
# ║                 CONFIGURACION - EDITA ACA                   ║
# ║  Cambia estos valores para ajustar como se generan las      ║
# ║  cartas de los jefes / profesores.                          ║
# ╚══════════════════════════════════════════════════════════════╝

BASE_DIR = Path(__file__).resolve().parent

# --- ARCHIVOS DE ENTRADA / SALIDA ---
CSV_CARTAS = BASE_DIR / "Cartas iniciales.xlsx - CARTAS PROFES.csv"
GODOT_PROJECT_DIR = BASE_DIR.parent / "ug-deck"
CARPETA_SALIDA = GODOT_PROJECT_DIR / "assets" / "cards_enemy"
CARPETA_ARTE = BASE_DIR / "card_art_jefes"

# --- CALIDAD / RESOLUCION ---
FACTOR_ESCALA = 2          # 1 = original (400x400), 2 = doble resolucion (800x800)
FILTRO_ARTE = "LANCZOS"    # "NEAREST", "BILINEAR" o "LANCZOS"

# --- DEPOSITOS DE PLANTILLAS ---
TEMPLATES_NORMAL_DIR = BASE_DIR / "templates"
TEMPLATES_JEFES_DIR = BASE_DIR / "templates jefes"

# Plantillas para enemigos normales (no jefes)
PLANTILLAS_NORMALES = {
    "Desertor":            TEMPLATES_NORMAL_DIR / "marco_desertor.png",
    "Ingresante":          TEMPLATES_NORMAL_DIR / "marco_ingresante.png",
    "Recursante":          TEMPLATES_NORMAL_DIR / "marco_recursante.png",
    "Ayudante de catedra": TEMPLATES_NORMAL_DIR / "marco_ayudante.png",
    "Ingeniero":           TEMPLATES_NORMAL_DIR / "marco_ingeniero.png",
}

# Plantillas exclusivas para Jefes (detectados por columna 'Arquetipo enemigo')
PLANTILLAS_JEFES = {
    "Desertor":            TEMPLATES_JEFES_DIR / "marco_desertor_jefe.png",
    "Ingresante":          TEMPLATES_JEFES_DIR / "marco_ingresante_jefe.png",
    "Recursante":          TEMPLATES_JEFES_DIR / "marco_recursante_jefe.png",
    "Ayudante de catedra": TEMPLATES_JEFES_DIR / "marco_ayudante-catedra -jefe.png", # Mapeo exacto del nombre de archivo
    "Ingeniero":           TEMPLATES_JEFES_DIR / "marco_ingeniero_jefe.png",
}

PLANTILLA_DEFAULT = TEMPLATES_NORMAL_DIR / "carta_vacia.png"

# --- FUENTES ---
FUENTE_ENERGIA   = BASE_DIR / "FONTS" / "AGENCYR.TTF"   # Fuente para el numero de energia
FUENTE_TEXTOS    = "C:/Windows/Fonts/segoeuib.ttf"       # Segoe UI Bold
FUENTE_TEXTOS_IT = "C:/Windows/Fonts/segoeuii.ttf"       # Segoe UI Italic

# Tamanos de fuente (en pixeles)
TAMANO_ENERGIA     = 22    # Numero de energia (circulo arriba a la izquierda)
TAMANO_NOMBRE      = 12    # Nombre de la carta (banner de arriba)
TAMANO_EFECTO      = 8.6   # Texto del efecto mecanico
TAMANO_DESCRIPCION = 8    # Texto de flavor/descripcion

# --- POSICIONES (coordenadas en pixeles) ---
POS_ENERGIA = (125, 85)    # Centro del circulo de energia
Y_NOMBRE    = 99          # Altura del nombre en el banner
Y_EFECTO    = 213         # Altura donde empieza el efecto
Y_DESCRIPCION = 242        # Altura donde empieza la descripcion

# --- TEXTO ---
MAX_CARACTERES_EFECTO      = 25   # Caracteres por linea del efecto
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
# MAPEADO DE ARTE DE CARTAS
# =========================

def simp_text(s):
    s = s.lower()
    s = s.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ñ", "n")
    s = s.replace("“", "").replace("”", "").replace("«", "").replace("»", "")
    return re.sub(r"[^a-z0-9]", "", s)

# Crear mapeo dinámico de archivos en card_art_jefes
def obtener_mapeo_arte():
    if not CARPETA_ARTE.exists():
        return {}
    # Obtener archivos de imagen y mapear sus nombres simplificados
    files = list(CARPETA_ARTE.glob("*.png")) + list(CARPETA_ARTE.glob("*.jpg")) + list(CARPETA_ARTE.glob("*.jpeg"))
    return {simp_text(f.stem): f for f in files}

MAPA_ARTE = obtener_mapeo_arte()

MAPA_NOMBRES_ESPECIALES = {
    "clasederepasomortal": "repasomortal",
    "recuperatorioanunciado": "recuanunciado",
    "temaqueentraseguro": "temaasegurado",
    "parcialconincisosorpresa": "incisosorpresa",
    "libroobligatorio": "bibliografiaobligatoria"
}


# =========================
# CARGA DE FUENTES
# =========================

def cargar_fuente(ruta, tamano):
    """Intenta cargar una fuente TTF. Si falla, usa Arial del sistema."""
    try:
        return ImageFont.truetype(str(ruta), tamano)
    except Exception:
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
    texto = texto.replace("\u00e1", "a").replace("\u00e9", "e").replace("\u00ed", "i")
    texto = texto.replace("\u00f3", "o").replace("\u00fa", "u").replace("\u00f1", "n")
    texto = re.sub(r"[^a-z0-9]+", "_", texto)
    texto = texto.strip("_")
    return texto


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
    rareza = str(rareza).strip()
    if rareza in PLANTILLAS_NORMALES:
        return rareza
    sin_acentos = rareza
    sin_acentos = sin_acentos.replace("\u00e1", "a").replace("\u00e9", "e").replace("\u00ed", "i")
    sin_acentos = sin_acentos.replace("\u00f3", "o").replace("\u00fa", "u").replace("\u00f1", "n")
    if sin_acentos in PLANTILLAS_NORMALES:
        return sin_acentos
    return rareza


def mapear_columnas(df):
    """Mapea dinamicamente las columnas para evitar errores de encoding."""
    columnas = list(df.columns)
    mapa = {}
    for col in columnas:
        col_lower = col.lower()
        if "nombre" in col_lower:
            mapa["nombre"] = col
        elif "coste" in col_lower:
            mapa["coste"] = col
        elif "efecto" in col_lower:
            mapa["efecto"] = col
        elif "descrip" in col_lower:
            mapa["descripcion"] = col
        elif "rareza" in col_lower:
            mapa["rareza"] = col
        elif "arquetipo" in col_lower:
            mapa["arquetipo"] = col
    return mapa


def generar_carta(fila, mapa_col):
    nombre = fila[mapa_col["nombre"]]
    coste = fila[mapa_col["coste"]]
    efecto = fila[mapa_col["efecto"]]
    descripcion = fila[mapa_col["descripcion"]] if "descripcion" in mapa_col else ""
    rareza = fila[mapa_col["rareza"]]
    arquetipo = str(fila.get(mapa_col.get("arquetipo"), "")) if "arquetipo" in mapa_col else ""

    rareza_normalizada = normalizar_rareza(rareza)
    
    # Seleccion de plantilla: utilizar solo las plantillas de 'templates jefes'
    plantilla = PLANTILLAS_JEFES.get(rareza_normalizada)
    if plantilla and plantilla.exists():
        print(f"  [JEFE] Usando plantilla de jefe para '{nombre}': {plantilla.name}")
    else:
        # Fallback a la plantilla por defecto si no se encuentra la de jefe especifica
        plantilla = PLANTILLA_DEFAULT
        print(f"  [AVISO] No se encontro plantilla de jefe para '{nombre}' (Rareza: {rareza_normalizada}), usando por defecto.")

    if not plantilla or not plantilla.exists():
        print(f"  [AVISO] Plantilla no encontrada para '{nombre}': usando plantilla por defecto.")
        plantilla = PLANTILLA_DEFAULT

    nombre_archivo = limpiar_nombre_archivo(nombre)
    
    # Buscar arte en el mapa simplificado de card_art_jefes
    s_nombre = simp_text(nombre)
    nombre_mapeado = MAPA_NOMBRES_ESPECIALES.get(s_nombre, s_nombre)
    ruta_arte = MAPA_ARTE.get(nombre_mapeado)

    # Cargar plantilla y redimensionar
    base_template = Image.open(plantilla).convert("RGBA")
    
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
            
            if FILTRO_ARTE == "NEAREST":
                down_filter = Image.Resampling.NEAREST if hasattr(Image, "Resampling") else Image.NEAREST
            elif FILTRO_ARTE == "BILINEAR":
                down_filter = Image.Resampling.BILINEAR if hasattr(Image, "Resampling") else Image.BILINEAR
            else:
                down_filter = Image.Resampling.LANCZOS if hasattr(Image, "Resampling") else Image.LANCZOS

            ancho_arte_esc = int(ANCHO_ARTE * FACTOR_ESCALA)
            alto_arte_esc = int(ALTO_ARTE * FACTOR_ESCALA)
            pos_arte_esc = (int(POS_ARTE[0] * FACTOR_ESCALA), int(POS_ARTE[1] * FACTOR_ESCALA))

            # Redimensionado pixel art
            arte_lowres = arte.resize((ANCHO_ARTE, ALTO_ARTE), down_filter)
            up_filter = Image.Resampling.NEAREST if hasattr(Image, "Resampling") else Image.NEAREST
            arte_redimensionado = arte_lowres.resize((ancho_arte_esc, alto_arte_esc), up_filter)
            
            # Floodfill mask para la ventana del arte
            alpha = base_template.getchannel('A')
            outside_mask = alpha.copy()
            ImageDraw.floodfill(outside_mask, (0, 0), 255)
            mask = ImageOps.invert(outside_mask)
            
            temp_canvas = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
            temp_canvas.paste(arte_redimensionado, pos_arte_esc)
            base_canvas.paste(temp_canvas, (0, 0), mask)
            
            print(f"  [ARTE] Integrando imagen: {ruta_arte.name} para '{nombre}'")
        except Exception as e:
            print(f"  [AVISO] Error cargando arte {ruta_arte.name}: {e}")

    # Superponer la plantilla
    carta = Image.alpha_composite(base_canvas, base_template)
    draw = ImageDraw.Draw(carta)

    x_centro = ancho // 2

    # --- ENERGIA ---
    coste_texto = str(int(coste)) if str(coste).replace(".", "", 1).isdigit() else str(coste)

    bbox = draw.textbbox((0, 0), coste_texto, font=fuente_energia)
    ancho_coste = bbox[2] - bbox[0]
    alto_coste = bbox[3] - bbox[1]

    x_coste = int(POS_ENERGIA[0] * FACTOR_ESCALA) - ancho_coste // 2
    y_coste = int(POS_ENERGIA[1] * FACTOR_ESCALA) - alto_coste // 2

    draw.text((x_coste, y_coste), coste_texto, font=fuente_energia, fill=COLOR_ENERGIA)

    # --- NOMBRE ---
    texto_centrado(
        draw=draw,
        texto=nombre,
        y=int(Y_NOMBRE * FACTOR_ESCALA),
        fuente=fuente_nombre,
        ancho_imagen=ancho,
        color=COLOR_TEXTO_NOMBRE
    )

    # --- EFECTO ---
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

    # --- DESCRIPCION ---
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

    # --- RAREZA ---
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
    salida = os.path.join(CARPETA_SALIDA, f"{nombre_archivo}.png")
    carta.save(salida)
    print(f"  [OK] {nombre} -> {nombre_archivo}.png")


# =========================
# LECTURA DEL CSV
# =========================

def leer_cartas():
    if not CSV_CARTAS.exists():
        raise FileNotFoundError(f"No se encontro el CSV de cartas: {CSV_CARTAS}")

    # Intentar primero con UTF-8
    try:
        df = pd.read_csv(CSV_CARTAS, skiprows=1, encoding="utf-8")
    except Exception:
        # Fallback a Latin-1
        df = pd.read_csv(CSV_CARTAS, skiprows=1, encoding="latin-1")
        
    df = df.dropna(how="all")
    df.columns = [col.strip() for col in df.columns]

    return df


# =========================
# PROGRAMA PRINCIPAL
# =========================

def main():
    df_cartas = leer_cartas()
    mapa_col = mapear_columnas(df_cartas)

    print("=" * 50)
    print("  GENERADOR DE CARTAS JEFES - UG DECK")
    print("=" * 50)
    print(f"  CSV: {CSV_CARTAS.name}")
    print(f"  Total de cartas: {len(df_cartas)}")
    print(f"  Salida: {CARPETA_SALIDA}")
    print()

    # Verificar que encontramos las columnas basicas
    columnas_requeridas = ["nombre", "coste", "efecto", "rareza"]
    faltantes = [c for c in columnas_requeridas if c not in mapa_col]
    if faltantes:
        print(f"  [ERROR] Faltan columnas clave detectadas en el CSV: {faltantes}")
        print(f"  Columnas leidas del archivo: {list(df_cartas.columns)}")
        return

    # Verificar fuentes
    print("  Fuentes:")
    print(f"    Energia:     {Path(FUENTE_ENERGIA).name} ({TAMANO_ENERGIA}px)")
    print(f"    Textos:      {Path(FUENTE_TEXTOS).name} ({TAMANO_NOMBRE}px nombre, {TAMANO_EFECTO}px efecto)")
    print(f"    Descripcion: {Path(FUENTE_TEXTOS_IT).name} ({TAMANO_DESCRIPCION}px)")
    print()

    # Verificar plantillas
    print("  Verificando plantillas base:")
    for rareza, ruta in PLANTILLAS_NORMALES.items():
        estado = "OK" if ruta.exists() else "FALTA"
        print(f"    Normal [{estado}] {rareza}: {ruta.name}")
    print()
    
    print("  Verificando plantillas de jefes:")
    for rareza, ruta in PLANTILLAS_JEFES.items():
        estado = "OK" if ruta.exists() else "FALTA"
        print(f"    Jefe   [{estado}] {rareza}: {ruta.name}")
    print()

    # Generar cartas
    print("  Generando cartas de jefes/profesores...")
    generadas = 0
    errores = 0
    for _, fila in df_cartas.iterrows():
        nombre = fila.get(mapa_col["nombre"], "???")
        try:
            generar_carta(fila, mapa_col)
            generadas += 1
        except Exception as e:
            print(f"  [ERROR] {nombre}: {e}")
            errores += 1

    print()
    print("=" * 50)
    print(f"  Listo. {generadas} cartas generadas, {errores} errores.")
    print("=" * 50)


if __name__ == "__main__":
    main()
