import os
import re
import textwrap
from pathlib import Path
import pandas as pd
from PIL import Image, ImageDraw, ImageFont


# =========================
# CONFIGURACIÓN GENERAL
# =========================
BASE_DIR = Path(__file__).resolve().parent
CSV_CARTAS = BASE_DIR / "Cartas iniciales.xlsx - CARTAS PROTA.csv"
PLANTILLA = BASE_DIR / "templates" / "carta_vacia.png"
CARPETA_SALIDA = BASE_DIR / "cartas_generadas"

os.makedirs(CARPETA_SALIDA, exist_ok=True)


# =========================
# FUENTES
# =========================

def cargar_fuente(ruta, tamaño):
    try:
        return ImageFont.truetype(ruta, tamaño)
    except:
        return ImageFont.load_default()


# Si tenés una fuente pixel, ponela en fuentes/pixel.ttf
FUENTE_PIXEL = BASE_DIR / "fuentes" / "pixel.ttf"

fuente_coste = cargar_fuente(FUENTE_PIXEL, 24)
fuente_nombre = cargar_fuente(FUENTE_PIXEL, 13)
fuente_tipo = cargar_fuente(FUENTE_PIXEL, 11)
fuente_efecto = cargar_fuente(FUENTE_PIXEL, 10)
fuente_descripcion = cargar_fuente(FUENTE_PIXEL, 9)


# =========================
# FUNCIONES DE TEXTO
# =========================

def limpiar_nombre_archivo(texto):
    texto = str(texto).lower()
    texto = texto.replace("á", "a").replace("é", "e").replace("í", "i")
    texto = texto.replace("ó", "o").replace("ú", "u").replace("ñ", "n")
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

def generar_carta(fila):
    nombre = fila["Nombre de la carta"]
    tipo = fila["Tipo"]
    coste = fila["Coste energía"]
    efecto = fila["Efecto"]
    descripcion = fila["Descripción"]
    rareza = fila["Rareza"]

    carta = Image.open(PLANTILLA).convert("RGBA")
    draw = ImageDraw.Draw(carta)

    ancho, alto = carta.size

    # =========================
    # COORDENADAS
    # =========================
    # Estas coordenadas están pensadas para tu imagen de 400x400.
    # Si algo queda corrido, tocá estos valores.

    x_centro = ancho // 2

    pos_coste = (125, 90)
    y_nombre = 100
    y_tipo = 210
    y_efecto = 236
    y_descripcion = 255
    y_rareza = 306

    # =========================
    # COLORES
    # =========================

    color_texto_oscuro = (20, 20, 30)
    color_azul = (15, 40, 120)
    color_rojo = (190, 35, 55)
    color_gris = (60, 60, 70)

    # =========================
    # COSTE
    # =========================

    coste_texto = str(int(coste)) if str(coste).replace(".", "", 1).isdigit() else str(coste)

    bbox = draw.textbbox((0, 0), coste_texto, font=fuente_coste)
    ancho_coste = bbox[2] - bbox[0]
    alto_coste = bbox[3] - bbox[1]

    x_coste = pos_coste[0] - ancho_coste // 2
    y_coste = pos_coste[1] - alto_coste // 2

    draw.text((x_coste, y_coste), coste_texto, font=fuente_coste, fill=color_texto_oscuro)

    # =========================
    # NOMBRE DE LA CARTA
    # =========================

    texto_centrado(
        draw=draw,
        texto=nombre,
        y=y_nombre,
        fuente=fuente_nombre,
        ancho_imagen=ancho,
        color=color_texto_oscuro
    )

    # =========================
    # TIPO
    # =========================

    texto_centrado(
        draw=draw,
        texto=str(tipo).upper(),
        y=y_tipo,
        fuente=fuente_tipo,
        ancho_imagen=ancho,
        color=color_azul
    )

    # =========================
    # EFECTO
    # =========================

    texto_multilinea_centrado(
        draw=draw,
        texto=efecto,
        x_centro=x_centro,
        y=y_efecto,
        fuente=fuente_efecto,
        color=color_texto_oscuro,
        max_caracteres=28,
        espacio_linea=11
    )

    # =========================
    # DESCRIPCIÓN
    # =========================

    texto_multilinea_centrado(
        draw=draw,
        texto=descripcion,
        x_centro=x_centro,
        y=y_descripcion,
        fuente=fuente_descripcion,
        color=color_rojo,
        max_caracteres=30,
        espacio_linea=10
    )

    # =========================
    # RAREZA
    # =========================

    texto_centrado(
        draw=draw,
        texto=str(rareza),
        y=y_rareza,
        fuente=fuente_descripcion,
        ancho_imagen=ancho,
        color=color_gris
    )

    # =========================
    # GUARDAR
    # =========================

    nombre_archivo = limpiar_nombre_archivo(nombre)
    salida = os.path.join(CARPETA_SALIDA, f"{nombre_archivo}.png")

    carta.save(salida)
    print(f"Carta generada: {salida}")


# =========================
# LECTURA DEL CSV
# =========================

def leer_cartas():
    # Tu CSV tiene una primera fila que dice "CARTAS DEL PROTA",
    # por eso usamos skiprows=1 para saltarla.
    if not CSV_CARTAS.exists():
        raise FileNotFoundError(f"No se encontró el CSV de cartas: {CSV_CARTAS}")

    df = pd.read_csv(CSV_CARTAS, skiprows=1)

    # Limpia filas vacías
    df = df.dropna(how="all")

    # Limpia espacios en nombres de columnas
    df.columns = [col.strip() for col in df.columns]

    return df


# =========================
# PROGRAMA PRINCIPAL
# =========================

def main():
    cartas = leer_cartas()

    print("Columnas encontradas:")
    print(cartas.columns.tolist())

    # for _, fila in cartas.iterrows():
    #     generar_carta(fila)
    fila = cartas.iloc[0]   # prueba con la primera carta
    generar_carta(fila)
    print("Listo. Todas las cartas fueron generadas.")


if __name__ == "__main__":
    main()
