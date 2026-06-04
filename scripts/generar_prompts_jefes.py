import os
import re
from pathlib import Path
import pandas as pd

# Directorio base
BASE_DIR = Path(__file__).resolve().parent
OUTPUT_FILE = BASE_DIR / "prompts_cartas_jefes.md"
CSV_CARTAS = BASE_DIR / "Cartas iniciales.xlsx - CARTAS PROFES.csv"

# Mapeo de descripciones visuales base usando llaves simplificadas para evitar fallos de matching
DESCRIPCIONES_BASE = {
    "bibliografiaextra": "Una pila desordenada y gigante de libros académicos que caen del cielo como meteoritos, con auras púrpuras de debuff. Hojas sueltas volando por todas partes. Fondo grisáceo.",
    "oralindividual": "Un estudiante asustado y sudando frío frente a un pizarrón de tiza donde se dibuja un gran micrófono de estilo clásico que brilla con un aura de ataque roja. Expresión de pánico total frente a la mirada inquisidora invisible de los profesores.",
    "cambiodeconsigna": "Una hoja de examen en el aire donde las letras y diagramas flotan y se reordenan mágicamente con destellos púrpuras y espirales. Cartas cayendo al descarte en el fondo.",
    "repasomortal": "Un profesor con aspecto amigable que de repente se transforma o revela una pose de combate con un aura de poder dorada y un escudo de defensa azul. Alrededor hay apuntes flotando como escudo.",
    "libroobligatorio": "Un libro gigante y pesado que cae aplastando a un pequeño personaje pixel art. Un aura púrpura de cansancio y debuff de distracción (reducir robo de cartas) flota en el aire.",
    "mesaexaminadora": "Un tribunal de tres profesores serios sentados detrás de un escritorio largo de madera, mirándolo con un aura roja y amenazante. Una hoja de parcial en el centro con un aura de ataque potente.",
    "criterioinvisible": "Un pizarrón borroso o un pergamino donde las líneas de texto son invisibles y brillan con un aura mágica púrpura. El profesor al lado ganando un buff de ataque con una flecha hacia arriba.",
    "cambiodefecha": "Un calendario de pared gigante donde las páginas se arrancan y vuelan de forma caótica en un torbellino de viento. Cartas descartándose en el aire.",
    
    "preguntaalazar": "Una gran ruleta o dado místico pixel art flotando, donde una de las caras brilla con un signo de interrogación de energía roja. Un rayo de ataque sale despedido al azar.",
    "miradaevaluadora": "Dos ojos gigantes y serios de profesor flotando en la oscuridad, emitiendo haces de luz roja (tipo escáner) que caen sobre un estudiante nervioso que tiembla.",
    "esoyalovimos": "Un profesor señalando con el dedo índice de manera acusadora hacia adelante. Del dedo sale una onda de choque expansiva de color rojo que golpea hacia el frente.",
    "silencioincomodo": "Un aula en penumbra con estudiantes sentados inmóviles con cremalleras pixel art en la boca. Un aura púrpura opresiva de estrés y silencio fluye por el aire.",
    "preguntaderepaso": "Un signo de interrogación de metal antiguo o piedra cayendo como un meteorito y rompiendo el suelo con chispas rojas. Apuntes volando por el aire.",
    "quienquierepasar": "Un pizarrón verde con una tiza flotando que dibuja una flecha brillante apuntando hacia un pupitre vacío de primera fila. El pupitre brilla con un halo de luz amarilla de advertencia.",
    "listaincompleta": "Un pergamino o lista larga de asistencia flotando, donde algunos nombres se desvanecen en humo rojo. A los lados, cartas de la mano del jugador cayendo en espiral.",
    "correccionseca": "Un bolígrafo o pluma estilográfica que tacha violentamente con una línea roja a través del aire. Partículas rojas de estrés y daño salen de la tachadura.",
    "recreocancelado": "La campana escolar pixel art rota por la mitad o envuelta en cadenas de hierro oscuras. Un reloj de arena vacío al lado.",
    "temasorpresa": "Una caja de regalo o cofre misterioso pixel art con el símbolo de un signo de interrogación brillante abriéndose, de donde sale un destello de energía roja salvaje.",
    "apunteperdido": "Una mochila escolar abierta boca abajo de la cual caen hojas y cuadernos que se desvanecen en el aire con un aura púrpura de descarte. Un rayo de daño rojo golpeando.",
    "explicacionrapida": "Un profesor que se mueve tan rápido que deja siluetas borrosas detrás de él mientras escribe fórmulas matemáticas en el pizarrón. Un escudo azul brillante a su alrededor.",

    "ejemplosinresolver": "Un pizarrón donde una ecuación matemática se detiene abruptamente con un gran signo de interrogación y un aura de confusión púrpura con espirales flotando alrededor.",
    "carpetaprolija": "Una carpeta de hojas perfectamente organizada y anillada que brilla con un aura de escudo azul muy gruesa y destellos dorados de orden.",
    "respuestaincompleta": "Una hoja de examen rota por la mitad, donde la mitad inferior falta. Un rayo rojo de ataque atraviesa la rotura destruyendo un escudo azul.",

    "explicacionconfusa": "Un torbellino o espiral de fórmulas matemáticas, palabras abstractas y signos de interrogación púrpuras flotando en el aire. El jugador tiene espirales en los ojos de confusión.",
    "unidadacumulativa": "Varios tomos de libros gruesos fusionándose uno sobre otro en el centro, emanando un aura de ataque roja que se vuelve más y más grande y brillante.",
    "parcialintegrador": "Una gran bola de energía de ataque conformada por hojas de parciales, libros, reglas y tizas orbitando en espiral. El ataque va dirigido hacia adelante como un meteoro.",
    "correccionenrojo": "Un examen con un gran '4' o una gran cruz roja trazada con marcador rojo brillante que emite un aura de estrés y partículas rojas.",
    "recuanunciado": "Una hoja de examen con un fénix o un destello verde/dorado de renacimiento elevándose de ella, mientras el profesor gana un escudo azul protector.",
    "preguntacapciosa": "Un cofre trampa (mímico) o un libro que se abre revelando colmillos y ojos brillantes. A los lados, cartas de descarte cayendo al fuego.",
    "consignaambigua": "Un cartel de dirección con flechas apuntando a múltiples lados contradictorios al mismo tiempo en la niebla. Un aura de confusión púrpura alrededor.",
    "teoriaacumulada": "Un gigante de piedra formado por libros apilados y apuntes, levantando los brazos con poder de ataque rojo y un escudo de piedra a su alrededor.",
    "incisosorpresa": "Una hoja de examen donde de la esquina inferior derecha brota de repente un tentáculo o una garra de energía roja de ataque sorpresa.",
    "revisionsevera": "Un profesor mirando un examen a través de una lupa gigante que enfoca un rayo de luz roja destructor, quemando la hoja. Cartas de la mano del jugador descartándose.",
    
    # --- Cartas de Enemigos Comunes (No Jefes) ---
    "borrarelpizarron": "Un borrador escolar pixel art flotando y barriendo a través de un pizarrón lleno de tiza, borrando todas las fórmulas y dejando un rastro de polvo de tiza en el aire. Un aura azul brillante de defensa.",
    "dictadoacelerado": "Una mano que sostiene una lapicera y escribe de manera hiperactiva y descontrolada en una hoja de papel, con líneas de movimiento rápidas y chispas de velocidad rojas. Onda expansiva de ataque.",
    "temaasegurado": "Una hoja de examen brillante que desciende del cielo envuelta en un aura dorada de poder absoluto, con un gran cartel de 'Aprobado' y destellos de energía de ataque.",
    "correccionoral": "Un profesor hablando o dictando de manera enérgica frente a la clase. Del profesor salen ondas de sonido y pequeñas espadas de energía roja de ataque que viajan hacia adelante.",
    "estoesbasico": "Un profesor de brazos cruzados mirándote con condescendencia y un aura púrpura de debuff/estrés. A los lados, el jugador tiene gotas de sudor y se ve superado mentalmente."
}

def simplificar_nombre(texto):
    texto = str(texto).lower()
    texto = texto.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ñ", "n")
    texto = texto.replace("“", "").replace("”", "").replace("«", "").replace("»", "")
    return re.sub(r"[^a-z0-9]", "", texto)

def leer_cartas():
    if not CSV_CARTAS.exists():
        raise FileNotFoundError(f"No se encontro el CSV de cartas: {CSV_CARTAS}")
    try:
        df = pd.read_csv(CSV_CARTAS, skiprows=1, encoding="utf-8")
    except Exception:
        df = pd.read_csv(CSV_CARTAS, skiprows=1, encoding="latin-1")
    df = df.dropna(how="all")
    df.columns = [col.strip() for col in df.columns]
    return df

def mapear_columnas(df):
    columnas = list(df.columns)
    mapa = {}
    for col in columnas:
        col_lower = col.lower()
        if "nombre" in col_lower:
            mapa["nombre"] = col
        elif "rareza" in col_lower:
            mapa["rareza"] = col
        elif "arquetipo" in col_lower:
            mapa["arquetipo"] = col
    return mapa

def generar_documento():
    df = leer_cartas()
    mapa_col = mapear_columnas(df)
    
    col_nombre = mapa_col["nombre"]
    col_rareza = mapa_col["rareza"]
    col_arquetipo = mapa_col["arquetipo"]
    
    # Agrupar cartas del CSV por su Rareza
    grupos_rareza = {}
    for _, fila in df.iterrows():
        nombre = fila[col_nombre]
        rareza = str(fila[col_rareza]).strip()
        arquetipo = str(fila.get(col_arquetipo, ""))
        es_jefe = "jefe" in arquetipo.lower()
        
        # Agrupar por rareza
        if rareza not in grupos_rareza:
            grupos_rareza[rareza] = []
        grupos_rareza[rareza].append((nombre, es_jefe))

    content = []
    content.append("# Prompts para Generar Arte de Cartas de Profesores y Jefes - UG DECK\n")
    content.append("## Especificaciones Técnicas del Área de Arte\n")
    content.append("| Propiedad | Valor |")
    content.append("|-----------|-------|")
    content.append("| Área de arte en la plantilla | **200 x 78 píxeles** |")
    content.append("| Proporción | **2.56:1** (apaisado/landscape) |")
    content.append("| Resolución recomendada para generar | **400 x 156 px** |")
    content.append("| Formato | PNG con fondo transparente o de color sólido |\n")
    
    content.append("> [!IMPORTANT]")
    content.append("> Las imágenes son **muy anchas y bajas** (tipo banner). Los personajes/objetos deben estar centrados y NO ocupar toda la altura, dejando un pequeño margen.\n")
    
    content.append("---\n")
    content.append("## Prompt Base (Template)\n")
    content.append("Copiá este prompt y reemplazá `{DESCRIPCION_VISUAL}` con la descripción de cada carta:\n")
    
    content.append("```")
    content.append("Genera una imagen en estilo pixel art retro de 16-bit para un juego de cartas universitario.")
    content.append("")
    content.append("ESPECIFICACIONES TÉCNICAS:")
    content.append("- Resolución: 400 x 156 píxeles (proporción 2.56:1, muy ancho y bajo, tipo banner)")
    content.append("- Estilo: pixel art limpio, colores vibrantes, contornos definidos de 1-2px")
    content.append("- Fondo: transparente o color sólido plano (sin gradientes)")
    content.append("- Sin texto, sin letras, sin números, sin UI")
    content.append("- El sujeto principal debe estar centrado y ocupar ~70-80% del espacio")
    content.append("- Paleta de colores limitada (máximo 16-24 colores)")
    content.append("")
    content.append("TEMÁTICA: Vida universitaria argentina, humor estudiantil de profesores y jefes malos, estética de videojuego retro")
    content.append("")
    content.append("ESCENA: {DESCRIPCION_VISUAL}")
    content.append("```\n")
    
    content.append("---\n")
    content.append("## Prompts por Carta\n")
    
    contador = 1
    # Asegurar un orden lógico de rarezas en el doc
    orden_rareza = ["Ayudante de cátedra", "Ayudante de catedra", "Desertor", "Ingresante", "Recursante", "Ingeniero"]
    rarezas_procesadas = set()
    
    # Procesar según orden preferido
    rarezas_disponibles = list(grupos_rareza.keys())
    for r_orden in orden_rareza:
        # Encontrar el grupo que coincida
        for r_disp in rarezas_disponibles:
            if r_disp not in rarezas_procesadas and simplificar_nombre(r_disp) == simplificar_nombre(r_orden):
                rarezas_procesadas.add(r_disp)
                content.append(f"### {r_disp}\n")
                content.append("---\n")
                
                for nombre, es_jefe in grupos_rareza[r_disp]:
                    nombre_simp = simplificar_nombre(nombre)
                    desc = DESCRIPCIONES_BASE.get(nombre_simp, "Descripción visual pendiente.")
                    
                    tipo_carta = "JEFE" if es_jefe else "ENEMIGO COMÚN"
                    
                    content.append(f"#### {contador}. {nombre} ({tipo_carta})")
                    content.append("```")
                    content.append("Genera una imagen en estilo pixel art retro de 16-bit para un juego de cartas universitario.")
                    content.append("")
                    content.append("ESPECIFICACIONES TÉCNICAS:")
                    content.append("- Resolución: 400 x 156 píxeles (proporción 2.56:1, muy ancho y bajo, tipo banner)")
                    content.append("- Estilo: pixel art limpio, colores vibrantes, contornos definidos de 1-2px")
                    content.append("- Fondo: transparente o color sólido plano (sin gradientes)")
                    content.append("- Sin texto, sin letras, sin números, sin UI")
                    content.append("- El sujeto principal debe estar centrado y ocupar ~70-80% del espacio")
                    content.append("")
                    content.append(f"ESCENA: {desc}")
                    content.append("```\n")
                    contador += 1

    # Procesar cualquier otra rareza sobrante que no esté en el orden de arriba
    for r_disp in rarezas_disponibles:
        if r_disp not in rarezas_procesadas:
            content.append(f"### {r_disp}\n")
            content.append("---\n")
            for nombre, es_jefe in grupos_rareza[r_disp]:
                nombre_simp = simplificar_nombre(nombre)
                desc = DESCRIPCIONES_BASE.get(nombre_simp, "Descripción visual pendiente.")
                tipo_carta = "JEFE" if es_jefe else "ENEMIGO COMÚN"
                content.append(f"#### {contador}. {nombre} ({tipo_carta})")
                content.append("```")
                content.append("Genera una imagen en estilo pixel art retro de 16-bit para un juego de cartas universitario.")
                content.append("")
                content.append("ESPECIFICACIONES TÉCNICAS:")
                content.append("- Resolución: 400 x 156 píxeles (proporción 2.56:1, muy ancho y bajo, tipo banner)")
                content.append("- Estilo: pixel art limpio, colores vibrantes, contornos definidos de 1-2px")
                content.append("- Fondo: transparente o color sólido plano (sin gradientes)")
                content.append("- Sin texto, sin letras, sin números, sin UI")
                content.append("- El sujeto principal debe estar centrado y ocupar ~70-80% del espacio")
                content.append("")
                content.append(f"ESCENA: {desc}")
                content.append("```\n")
                contador += 1
            
    content.append("## Tips para Mejores Resultados\n")
    content.append("> [!TIP]")
    content.append("> - **Gemini:** Excelente resultado para pixel art. Agregá 'retro game sprite style' si querés más detalle.")
    content.append("> - **Midjourney:** Usá `--ar 5:2 --style raw --s 50` al final.")
    content.append("> - Recortá las imágenes generadas a exactamente **400 x 156 px** antes de guardarlas en la carpeta `card_art` con el nombre de la carta (en minúsculas y separado por guiones bajos) para que los scripts las integren automáticamente.\n")

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(content))

if __name__ == "__main__":
    generar_documento()
    print(f"Documento de prompts para {len(DESCRIPCIONES_BASE)} cartas de enemigos generado exitosamente.")
