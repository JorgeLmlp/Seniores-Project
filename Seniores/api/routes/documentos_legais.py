"""Documentos publicos para consulta antes do cadastro e do consentimento."""

import json
from pathlib import Path
from flask import Blueprint, jsonify

documentos_legaisbp = Blueprint('documentos_legais', __name__)
DOCUMENTOS = Path(__file__).resolve().parents[1] / 'documentos'


def carregar_documento(nome):
    return jsonify(json.loads((DOCUMENTOS / f'{nome}.json').read_text(encoding='utf-8')))


@documentos_legaisbp.get('/')
def inicio():
    return jsonify(servico='Seniores API', documentos={
        'termos_de_uso': '/termos-de-uso',
        'consentimento': '/termo-consentimento',
    })


@documentos_legaisbp.get('/termos-de-uso')
def termos_de_uso():
    return carregar_documento('termos-de-uso')


@documentos_legaisbp.get('/termo-consentimento')
def consentimento():
    return carregar_documento('consentimento')
