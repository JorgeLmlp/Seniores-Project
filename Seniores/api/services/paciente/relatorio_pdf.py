"""Apresentação do histórico registrado, sem inferir diagnósticos ou prescrições."""
from datetime import datetime
from io import BytesIO
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, LongTable, TableStyle


AZUL = colors.HexColor('#234F73')
CINZA = colors.HexColor('#526272')
CLARO = colors.HexColor('#F1F5F8')
LARGURA = A4[0] - 36 * mm
ESTILOS = {
    'texto': ParagraphStyle('texto', fontName='Helvetica', fontSize=10, leading=14,
                            textColor=colors.HexColor('#202B34'), spaceAfter=5),
    'titulo': ParagraphStyle('titulo', fontName='Helvetica-Bold', fontSize=23, leading=28,
                             textColor=AZUL, spaceAfter=10),
    'secao': ParagraphStyle('secao', fontName='Helvetica-Bold', fontSize=13, leading=18,
                            textColor=AZUL, spaceBefore=16, spaceAfter=8, keepWithNext=True),
    'subtitulo': ParagraphStyle('subtitulo', fontName='Helvetica-Bold', fontSize=10, leading=14,
                                spaceBefore=7, spaceAfter=4, keepWithNext=True, textColor=AZUL),
    'nota': ParagraphStyle('nota', fontName='Helvetica', fontSize=9, leading=12,
                           textColor=CINZA, spaceAfter=6),
    'cabecalho': ParagraphStyle('cabecalho', fontName='Helvetica-Bold', fontSize=9,
                                leading=12, textColor=colors.white, alignment=TA_LEFT),
}
ESTILOS['nota_secao'] = ParagraphStyle('nota_secao', parent=ESTILOS['nota'], keepWithNext=True)


def texto(valor):
    if valor is None or valor == '' or valor == []:
        return 'Não informado'
    if isinstance(valor, (list, tuple)):
        return '; '.join(texto(v) for v in valor) or 'Não informado'
    if hasattr(valor, 'value'):
        valor = valor.value
    return str(valor)


def par(valor, estilo='texto'):
    # Dados digitados não podem virar marcação HTML no relatório.
    return Paragraph(escape(texto(valor)).replace('\n', '<br/>'), ESTILOS[estilo])


def data(valor, hora=True):
    if not valor:
        return 'Não informada'
    if isinstance(valor, str):
        try:
            valor = datetime.fromisoformat(valor.replace('Z', '+00:00'))
        except ValueError:
            return valor
    formato = '%d/%m/%Y %H:%M' if hora else '%d/%m/%Y'
    if hora and getattr(valor, 'tzinfo', None) is not None:
        formato += ' %z'
    return valor.strftime(formato)


def tabela(colunas, linhas, proporcoes=None):
    pesos = proporcoes or [1] * len(colunas)
    conteudo = [[par(c, 'cabecalho') for c in colunas]]
    conteudo.extend([[par(c) for c in linha] for linha in linhas])
    t = LongTable(conteudo, colWidths=[LARGURA * p / sum(pesos) for p in pesos],
                  repeatRows=1, splitByRow=1, splitInRow=1, hAlign='LEFT')
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), AZUL),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, CLARO]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LINEBELOW', (0, 0), (-1, 0), 0.5, AZUL),
        ('LINEBELOW', (0, 1), (-1, -1), 0.25, colors.HexColor('#DAE2E8')),
    ]))
    return t


def gerar_pdf_clinico(h):
    paciente = h['paciente']
    periodo = h['periodo']
    modo = periodo.get('modo', 'mensal')
    if modo == 'mensal':
        mes_ano = f"{periodo['mes']:02d}/{periodo['ano']}"
    elif modo == 'todo':
        mes_ano = 'Histórico completo até a emissão'
    else:
        from datetime import timedelta
        mes_ano = f"{periodo['inicio']:%d/%m/%Y} a {(periodo['fim'] - timedelta(days=1)):%d/%m/%Y}"
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
                            topMargin=24 * mm, bottomMargin=20 * mm, pageCompression=0,
                            title=f'Relatório de acompanhamento - {mes_ano}', author='Seniores')
    story = [par('Relatório de acompanhamento', 'titulo'),
             par(f'Período dos registros: {mes_ano}', 'subtitulo'),
             tabela(['Paciente', 'Identificação'], [[paciente.name,
                 f"Código: {paciente.id}\nIdade: {texto(paciente.idade)}\nTipo sanguíneo: {texto(paciente.tipo_sanguineo)}"]], [2, 1]),
             Spacer(1, 8),
             par('Histórico informado no aplicativo por pacientes e pessoas envolvidas nos cuidados. '
                 'Não contém interpretação clínica automática. Campos ausentes não indicam ausência de sintomas.', 'nota')]

    def secao(titulo, registros, colunas=None, linhas=None, pesos=None, nota=None):
        story.append(par(titulo, 'secao'))
        if nota:
            story.append(par(nota, 'nota_secao'))
        if not registros:
            story.append(par('Nenhum registro disponível.', 'nota'))
            return False
        if colunas:
            story.append(tabela(colunas, linhas, pesos))
        return True

    def campo(rotulo, valor):
        story.append(par(f'{rotulo}: {texto(valor)}'))

    story.append(par('Visão geral do período', 'secao'))
    story.append(par(f"Diários: {len(h['diarios'])}  •  Aferições: {len(h['sinais_vitais'])}  •  "
                     f"Fichas de incidentes: {len(h['incidentes'])}  •  "
                     f"Consultas: {len(h['consultas'])}  •  Exames agendados: {len(h['exames_agendados'])}"))
    perguntas = [r for r in h['diarios'] if r.duvidas]
    if perguntas:
        story.append(par('Dúvidas registradas para a consulta', 'subtitulo'))
        for r in perguntas:
            campo(data(r.data_criacao), r.duvidas)

    story.append(par('Alergias informadas', 'subtitulo'))
    alergias = [a for r in h['dietas'] for a in (r.alergias or [])]
    story.append(par('; '.join(dict.fromkeys(alergias)) if alergias else 'Não há informação de alergias cadastrada.'))
    story.append(par('Informação vigente na emissão, conforme cadastro de dieta e restrições.', 'nota'))

    meds = h['medicamentos']
    nomes = {r.id: r.nome for r in meds}
    secao('Medicamentos cadastrados', meds, ['Medicamento / dose', 'Frequência / horários', 'Orientações registradas'],
          [[f'{r.nome}\n{r.dosagem}', f'{texto(r.frequencia)}\n{texto(r.horarios)}',
            '\n'.join(filter(None, [r.descricao, '; '.join(r.alertas or [])]))] for r in meds], [1.3, 1, 1.5],
          'Cadastro vigente na emissão do relatório; não representa necessariamente a prescrição de todo o período.')

    sinais = h['sinais_vitais']
    secao('Sinais vitais e medidas', sinais,
          ['Data / hora', 'Pressão arterial', 'Glicemia', 'Temperatura', 'Freq. cardíaca', 'Saturação'],
          [[data(r.data), r.pressao_art, r.glicemia, r.temperatura, r.freq_cardiaca, r.saturacao] for r in sinais],
          [1.5, 1.15, 1, 1.1, 1.05, 1],
          'Valores transcritos como cadastrados. Unidades não informadas no registro não foram presumidas.')

    diarios = h['diarios']
    def nivel(r, numerico, qualitativo):
        n = getattr(r, numerico, None)
        return f'{n}/10' if n is not None else texto(getattr(r, qualitativo, None)).capitalize()
    secao('Diário de saúde', diarios, ['Data / hora', 'Humor', 'Dor', 'Apetite', 'Mobilidade', 'Sono'],
          [[data(r.data_criacao), nivel(r, 'humor_nivel', 'humor'), nivel(r, 'dor_nivel', 'dor'),
            nivel(r, 'apetite_nivel', 'fome'), nivel(r, 'mobilidade_nivel', 'mobilidade'), nivel(r, 'sono_nivel', 'sono')]
           for r in diarios], [1.5, 1, 1, 1, 1.2, 1],
          'Escalas informadas de 0 a 10: valores maiores indicam mais dor; em humor, apetite e mobilidade, melhor avaliação. '
          'Sono é apresentado como registrado, sem conversão para horas.')
    for r in diarios:
        if r.descricao or r.incidentes:
            story.append(par(f'Anotações do diário — {data(r.data_criacao)}', 'subtitulo'))
            if r.descricao:
                campo('Observações', r.descricao)
            for i in r.incidentes or []:
                campo(f"Ocorrência no diário ({texto(i.get('hora'))})",
                      f"{texto(i.get('titulo'))} — {texto(i.get('descricao'))}\nGravidade informada: {texto(i.get('gravidade'))}")

    if secao('Incidentes e providências', h['incidentes']):
        for r in h['incidentes']:
            story.append(par(f'{data(r.data_hora)} — {texto(r.tipo)}', 'subtitulo'))
            campo('Descrição', r.descricao)
            campo('Gravidade informada', r.gravidade)
            campo('Providências registradas', r.providencias)

    for chave, titulo, exame in [('consultas', 'Consultas do período', False), ('exames_agendados', 'Exames agendados no período', True)]:
        registros = sorted(h[chave], key=lambda r: str(r.dados.get('dataHora', '')))
        if not secao(titulo, registros):
            continue
        for r in registros:
            d = r.dados
            nome = d.get('nomeExame') if exame else d.get('nomeDoutor')
            story.append(par(f"{data(d.get('dataHora'))} — {texto(nome)}", 'subtitulo'))
            concluido = d.get('concluido' if exame else 'concluida')
            campo('Situação registrada', 'Concluído' if concluido else 'Histórico (sem confirmação de conclusão)' if d.get('historico') else 'Agendado / não concluído')
            if not exame:
                campo('Especialidade', d.get('especialidade'))
                campo('Motivo da consulta', d.get('motivo'))
                campo('Exames solicitados', d.get('exames'))
            campo('Local', d.get('local') or ', '.join(str(d[k]) for k in ('logradouro', 'bairro', 'cidade', 'estado') if d.get(k)))
            if d.get('alertas'):
                campo('Observações / alertas cadastrados', d['alertas'])

    secao('Documentos de exames disponíveis', h['documentos_exames'], ['Exame', 'Data do exame', 'Arquivo'],
          [[r.nome, data(r.data_exame, False), r.nome_arquivo] for r in h['documentos_exames']], [1.2, 1, 1.8],
          'Relação de arquivos cadastrados. Os laudos originais não estão incorporados neste PDF.')
    if secao('Dieta e restrições cadastradas', h['dietas'], nota='Informações vigentes na emissão do relatório.'):
        for r in h['dietas']:
            campo('Dieta', r.descricao_dieta)
            campo('Restrições informadas', r.restricoes)
            if r.observacoes:
                campo('Observações', r.observacoes)

    secao('Registro de conclusão das doses', h['doses'], ['Data', 'Horário', 'Medicamento', 'Situação'],
          [[data(r.data, False), r.horario, nome, 'Concluída' if r.concluida else 'Não concluída'] for r, nome in h['doses']],
          [1, .65, 1.5, 1], 'Somente doses com marcação no aplicativo. Ausência de marcação não permite concluir se houve administração.')
    secao('Administrações registradas', h['administracoes'], ['Data / hora', 'Medicamento', 'Confirmado por / observação'],
          [[data(r.administrado_em), nomes.get(r.medicamento_id, f'Medicamento #{r.medicamento_id}'),
            f"{texto(r.confirmado_por)}\n{texto(r.observacao)}"] for r in h['administracoes']], [1, 1.2, 1.8],
          'Ficha de administrações separada das marcações de doses; os registros não foram somados para estimar adesão.')
    secao('Contatos de apoio', h['contatos'], ['Nome', 'Vínculo', 'Telefone'],
          [[r.nome, r.vinculo or r.tipo, r.telefone] for r in h['contatos']], [1.5, 1, 1])
    secao('Estoque cadastrado', h['estoque'], ['Item', 'Quantidade', 'Mínimo cadastrado'],
          [[r.nome, r.quantidade, r.quantidade_minima] for r in h['estoque']], [2, 1, 1],
          'Posição do estoque na emissão, sem reconstrução de movimentações anteriores.')

    emitido = datetime.now().strftime('%d/%m/%Y %H:%M')
    def pagina(canvas, documento):
        canvas.saveState()
        canvas.setFillColor(AZUL)
        canvas.setFont('Helvetica-Bold', 10)
        canvas.drawString(18 * mm, A4[1] - 13 * mm, 'SENIORES  |  Acompanhamento de saúde')
        canvas.setFont('Helvetica', 9)
        canvas.drawRightString(A4[0] - 18 * mm, A4[1] - 13 * mm, mes_ano)
        canvas.setStrokeColor(colors.HexColor('#DAE2E8'))
        canvas.line(18 * mm, 16 * mm, A4[0] - 18 * mm, 16 * mm)
        canvas.setFillColor(CINZA)
        canvas.setFont('Helvetica', 8)
        canvas.drawString(18 * mm, 11 * mm, f'Paciente #{paciente.id}  •  Emitido em {emitido}  •  Uso confidencial')
        canvas.drawRightString(A4[0] - 18 * mm, 11 * mm, f'Página {documento.page}')
        canvas.restoreState()
    doc.build(story, onFirstPage=pagina, onLaterPages=pagina)
    return buffer.getvalue()
