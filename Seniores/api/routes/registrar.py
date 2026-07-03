from flask import Blueprint, render_template, request, redirect, url_for 
from app import app

registrar_cuidador = Blueprint('registrar', __name__)

registrar_cuidador.route('/registrar_cuidador/', methods=['GET', 'POST'])(registrar_cuidador)
