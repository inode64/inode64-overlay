"""Avisos de healthchecks en español (correo y Slack).

Fichero propio de INODE64, no forma parte de healthchecks. Lo usan las
plantillas emails/alert-* y hc/integrations/slack/transport.py para que los
dos canales digan lo mismo: si la tarea ha terminado con error, no ha dado
señal o se ha procesado correctamente, y los datos para localizar el fallo.
"""

from __future__ import annotations

from datetime import datetime
from datetime import timedelta as td
from typing import Any
from zoneinfo import ZoneInfo

from django import template
from django.utils.timezone import now

register = template.Library()

TZ = ZoneInfo("Europe/Madrid")
TIPOS = {None: "correcto", "fail": "fallo", "start": "inicio", "log": "registro", "ign": "ignorado"}


@register.filter
def duracion(d: td | None) -> str:
    """timedelta -> «2 h 5 min» (las dos unidades más significativas)."""
    if d is None:
        return ""
    total = max(int(d.total_seconds()), 0)
    dias, resto = divmod(total, 86400)
    horas, resto = divmod(resto, 3600)
    minutos, segundos = divmod(resto, 60)
    partes = []
    if dias:
        partes.append("1 día" if dias == 1 else f"{dias} días")
    if horas:
        partes.append(f"{horas} h")
    if minutos:
        partes.append(f"{minutos} min")
    if segundos and not dias and not horas:
        partes.append(f"{segundos} s")
    return " ".join(partes[:2]) if partes else "0 s"


@register.filter
def fecha(dt: datetime | None) -> str:
    """Fecha y hora en la zona de Madrid: «03/10/2026 16:51»."""
    return dt.astimezone(TZ).strftime("%d/%m/%Y %H:%M") if dt else ""


@register.filter
def hace(dt: datetime | None) -> str:
    return f"hace {duracion(now() - dt)}" if dt else ""


def cliente(ua: str) -> str:
    """Nombre corto del programa que envió el ping: «runitor/v1.5.0», «curl/8.21.0»."""
    if not ua:
        return ""
    nombre, _, version = ua.split()[0].partition("/")
    # runitor/v1.5.0-beta.2.0.2026...+dirty -> runitor/v1.5.0
    version = version.split("-")[0]
    return (f"{nombre}/{version}" if version else nombre)[:40]


def origen(ping: Any) -> str:
    partes = [p for p in (ping.remote_addr, cliente(ping.ua)) if p]
    return " · ".join(partes)


def programacion(check: Any) -> str:
    if check.kind in ("cron", "oncalendar"):
        return f"«{check.schedule}» ({check.tz}), margen {duracion(check.grace)}"
    return f"cada {duracion(check.timeout)}, margen {duracion(check.grace)}"


@register.filter
def cola(body: str | None, lineas: int = 30) -> str:
    """Últimas líneas del registro: los errores y los totales están al final."""
    if not body:
        return ""
    todas = body.strip("\n").rstrip().splitlines()
    texto = "\n".join(todas[-lineas:])
    if len(texto) > 4000:
        texto = "[...]\n" + texto[-4000:]
    elif len(todas) > lineas:
        texto = f"[... {len(todas) - lineas} líneas anteriores]\n" + texto
    return texto


def datos_aviso(flip: Any, ping: Any = None, body: str | None = None, lineas: int = 30) -> dict[str, Any]:
    """Todo lo que muestra un aviso, igual para correo y Slack."""
    check = flip.owner
    nombre = check.name_then_code()
    proyecto = check.project.name
    campos: list[tuple[str, str]] = []
    nota = ""

    if flip.new_status == "up":
        estado = "CORRECTO"
        frase = f"La tarea «{nombre}» se ha procesado correctamente."
        detalle = ""
        try:
            caido = flip.down_duration
        except AssertionError:
            caido = None
        if caido:
            detalle = f"recuperado tras {duracion(caido)}"
            campos.append(("Estuvo en fallo", f"{duracion(caido)} (desde el {fecha(flip.created - caido)})"))
    elif flip.reason == "fail":
        estado = "ERROR"
        frase = f"La tarea «{nombre}» ha terminado con error."
        if ping is not None and ping.exitstatus is not None:
            detalle = f"código de salida {ping.exitstatus}"
            campos.append(("Motivo", f"señal de fallo, código de salida {ping.exitstatus}"))
        else:
            detalle = "señal de fallo"
            campos.append(("Motivo", "la tarea envió una señal de fallo"))
    else:
        estado = "SIN SEÑAL"
        frase = f"La tarea «{nombre}» no ha avisado a tiempo."
        campos.append(("Motivo", "no se recibió la señal de fin dentro del plazo"))
        vencio = flip.created
        campos.append(
            ("Se esperaba", f"antes del {fecha(vencio - check.grace)} (el margen de {duracion(check.grace)} venció el {fecha(vencio)})")
        )
        if ping is None:
            detalle = "nunca ha dado señal"
            nota = "La tarea nunca ha enviado una señal."
        elif ping.kind == "start":
            detalle = f"empezó {hace(ping.created)} y no ha terminado"
            nota = f"La tarea empezó el {fecha(ping.created)} y no ha terminado."
        else:
            detalle = f"última señal {hace(ping.created)}"
            nota = "La tarea no ha vuelto a ejecutarse desde entonces."

    if ping is not None:
        ultimo = f"{TIPOS.get(ping.kind, ping.kind)}, {fecha(ping.created)} ({hace(ping.created)})"
        campos.append(("Último ping", ultimo))
        # En un aviso de falta de señal el último ping es de una ejecución anterior
        if estado != "SIN SEÑAL" and ping.kind in (None, "fail") and ping.duration is not None:
            campos.append(("Duración", duracion(ping.duration)))
        if origen(ping):
            campos.append(("Origen", origen(ping)))
    else:
        campos.append(("Último ping", "nunca"))

    if proyecto:
        campos.append(("Proyecto", proyecto))
    if check.tags_list():
        campos.append(("Etiquetas", " ".join(check.tags_list())))
    campos.append(("Programación", programacion(check)))

    asunto = f"[{estado}] {proyecto + ' - ' if proyecto else ''}{nombre}"
    if detalle:
        asunto += f" ({detalle})"

    # Sin señal no hay registro de esta ejecución: el del último ping es antiguo
    registro = "" if estado == "SIN SEÑAL" else cola(body, lineas)
    enlace = check.cloaked_url()

    ancho = max(len(e) for e, _ in campos) + 1
    texto = [f"{estado}: {frase[0].lower()}{frase[1:]}", ""]
    texto += [f"{(e + ':').ljust(ancho + 1)} {v}" for e, v in campos]
    if nota:
        texto += ["", nota]
    if check.desc:
        texto += ["", "Descripción:", check.desc]
    if registro:
        texto += ["", "Final del registro:", "-------------------", registro]
    texto += ["", f"Ver el check: {enlace}"]

    return {
        "estado": estado,
        "correcto": flip.new_status == "up",
        "frase": frase,
        "detalle": detalle,
        "nota": nota,
        "asunto": asunto,
        "campos": campos,
        "registro": registro,
        "enlace": enlace,
        "descripcion": check.desc,
        "texto": "\n".join(texto),
    }


@register.simple_tag
def aviso(flip: Any, ping: Any = None, body: str | None = None) -> dict[str, Any]:
    return datos_aviso(flip, ping, body)
