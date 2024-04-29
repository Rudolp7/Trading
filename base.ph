# Importa las bibliotecas necesarias
import time  # Para gestionar el tiempo
import ccxt  # Biblioteca para interactuar con intercambios de criptomonedas
import pandas as pd  # Para el manejo de datos
import pandas_ta as ta  # Paquete de análisis técnico para pandas
from telebot import TeleBot  # Para enviar mensajes a través de Telegram
from termcolor import colored  # Para resaltar texto en la consola

# Configuración inicial

# Configuración de las claves de la API de Binance y del bot de Telegram
api_key = ""  # Clave de API de Binance
api_secret = ""  # Secreto de API de Binance
telegram_bot_token = ""  # Token del bot de Telegram
telegram_chat_id = ""  # ID del chat de Telegram

# Lista de pares de criptomonedas que se van a monitorear
pares = [
    "BTC/USDT",
    "ETH/USDT",
    "ADA/USDT",
    "SHIB/USDT",
    "RAY/USDT",
    "SOL/USDT",
    "BNB/USDT",
    "DOGE/USDT",
    "AVAX/USDT",
    "THETA/USDT",
]

# Lista de temporalidades que se van a monitorear
temporalidades = ["1h", "4h", "1d", "1w", "1M"]

# Crear una instancia de la clase ccxt para el exchange Binance
exchange = ccxt.binance({"apiKey": api_key, "secret": api_secret})

# Crear una instancia del bot de Telegram
bot = TeleBot(telegram_bot_token)


# Función para calcular la media móvil exponencial (EMA)
def calcular_ema(df, periodo):
    return df["close"].ewm(span=periodo, adjust=False).mean()


# Función para calcular la media móvil simple (MA)
def calcular_ma(df, periodo):
    return df["close"].rolling(window=periodo).mean()


# Función para calcular el índice de fuerza relativa (RSI)
def calcular_rsi(cierre, periodo=14):
    return ta.rsi(cierre, length=periodo)


# Función para enviar mensajes a través de Telegram
def enviar_mensaje_telegram(mensaje):
    bot.send_message(telegram_chat_id, mensaje)


# Función para revisar si se produce un cruce entre la EMA y la MA, y si el RSI está por encima de cierto umbral
def revisar_cruce_ema_ma_y_rsi(par, temporalidad):
    # Obtener datos de OHLCV (Open, High, Low, Close, Volume) del par y temporalidad especificados
    df = pd.DataFrame(
        exchange.fetch_ohlcv(par, temporalidad),
        columns=["timestamp", "open", "high", "low", "close", "volume"],
    )
    # Calcular la EMA21, MA50 y RSI
    df["EMA21"] = calcular_ema(df, 21)
    df["MA50"] = calcular_ma(df, 50)
    df["RSI"] = calcular_rsi(df["close"], 14)

    # Obtener el último y penúltimo registro del DataFrame
    ultimo = df.iloc[-1]
    penultimo = df.iloc[-2]

    # Comprobar si se ha producido un cruce de compra
    cruce_compra = (
        ultimo["EMA21"] > ultimo["MA50"] and penultimo["EMA21"] <= penultimo["MA50"]
    )
    return cruce_compra, ultimo["close"], ultimo["RSI"]


# Función principal del programa
def main():
    # Bucle infinito para monitorear continuamente el mercado
    while True:
        # Iterar sobre las temporalidades y los pares de criptomonedas
        for temporalidad in temporalidades:
            for par in pares:
                # Revisar si se produce un cruce entre la EMA y la MA, y si el RSI está por encima de cierto umbral
                cruce_compra, precio_actual, rsi_actual = revisar_cruce_ema_ma_y_rsi(
                    par, temporalidad
                )
                # Crear un mensaje con la información obtenida
                mensaje = f"[{temporalidad}] Cruce {'encontrado' if cruce_compra else 'no encontrado'} en {par}. Precio actual: {precio_actual}, RSI actual: {rsi_actual}"
                # Imprimir el mensaje en la consola con color verde si se encontró un cruce, rojo si no se encontró
                if cruce_compra:
                    print(colored(mensaje, "green"))
                    # Enviar el mensaje a través de Telegram si se encontró un cruce
                    enviar_mensaje_telegram(mensaje)
                else:
                    print(colored(mensaje, "red"))

        # Esperar un tiempo antes de realizar la próxima revisión del mercado
        tiempo_espera = 3600  # 1 hora en segundos
        while tiempo_espera > 0:
            mins, secs = divmod(tiempo_espera, 60)
            contador_regresivo = (
                f"\rPróxima revisión en {mins} minutos y {secs} segundos..."
            )
            print(contador_regresivo, end="", flush=True)
            time.sleep(1)
            tiempo_espera -= 1
        print("\nRealizando nueva revisión...")


# Llamada a la función principal si este script se ejecuta directamente
if __name__ == "__main__":
    main()
