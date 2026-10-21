from datetime import datetime
from io import BytesIO
from types import SimpleNamespace as Registro
import unittest

from pypdf import PdfReader
from services.paciente.relatorio_pdf import gerar_pdf_clinico


def exemplo_historico():
    """Dados fictícios, sem acesso ao banco, para testes e prévia visual."""
    momento = datetime(2026, 10, 20, 8, 30)
    h = {k: [] for k in ('medicamentos', 'sinais_vitais', 'diarios', 'incidentes', 'consultas',
                         'exames_agendados', 'documentos_exames', 'dietas', 'doses', 'administracoes', 'contatos', 'estoque')}
    h.update(paciente=Registro(id=0, name='Paciente demonstrativo — dados fictícios', idade=78, tipo_sanguineo='O+'),
             periodo={'ano': 2026, 'mes': 10})
    h['medicamentos'] = [Registro(id=1, nome='Medicamento demonstrativo', dosagem='Conforme cadastro',
                                  frequencia='Diária', horarios=['08:00', '20:00'],
                                  descricao='Orientação transcrita do cadastro.', alertas=['Observação informada pela família.'])]
    h['sinais_vitais'] = [Registro(data=momento, pressao_art='120/80 mmHg', glicemia='98 mg/dL',
                                  temperatura='36,5 °C', freq_cardiaca='72 bpm', saturacao='97%')]
    h['diarios'] = [Registro(data_criacao=momento, humor_nivel=7, dor_nivel=0, apetite_nivel=8,
                             mobilidade_nivel=6, sono_nivel=None, humor='bom', dor='bom', fome='bom',
                             mobilidade='razoavel', sono=None, descricao='Alimentação aceita. Caminhada acompanhada.',
                             duvidas='Levar o registro de sono para conversar na consulta.',
                             incidentes=[{'hora': '10:00', 'titulo': 'Desconforto', 'descricao': 'Relato registrado no diário.', 'gravidade': 'Baixa'}])]
    h['incidentes'] = [Registro(data_hora=momento, tipo='Desequilíbrio', descricao='Episódio relatado ao levantar.',
                                gravidade='Não informada', providencias='Acompanhante permaneceu junto ao paciente.')]
    h['consultas'] = [Registro(dados={'nomeDoutor': 'Profissional demonstrativo', 'especialidade': 'Clínica médica',
                                     'dataHora': momento.isoformat(), 'concluida': True, 'local': 'Consultório demonstrativo',
                                     'motivo': 'Acompanhamento periódico', 'exames': ['Hemograma'], 'alertas': []})]
    h['exames_agendados'] = [Registro(dados={'nomeExame': 'Hemograma', 'dataHora': '2026-10-25T09:00:00', 'local': 'Laboratório demonstrativo', 'concluido': False})]
    h['documentos_exames'] = [Registro(nome='Exame anterior', data_exame=momento, nome_arquivo='exemplo.pdf')]
    h['dietas'] = [Registro(descricao_dieta='Conforme orientação cadastrada.', restricoes=['Restrição informada no cadastro'], alergias=['Alergia demonstrativa'], observacoes=None)]
    h['doses'] = [(Registro(data='2026-10-20', horario='08:00', concluida=True), 'Medicamento demonstrativo')]
    h['administracoes'] = [Registro(administrado_em=momento, medicamento_id=1, confirmado_por='Cuidador demonstrativo', observacao='Registro de exemplo.')]
    h['contatos'] = [Registro(nome='Contato demonstrativo', tipo='familiar', vinculo='Responsável', telefone='(00) 00000-0000')]
    h['estoque'] = [Registro(nome='Item demonstrativo', quantidade=10, quantidade_minima=2)]
    return h


class RelatorioLegivelTest(unittest.TestCase):
    def test_campos_legiveis_sem_json_e_com_acentos(self):
        pdf = PdfReader(BytesIO(gerar_pdf_clinico(exemplo_historico())))
        texto = '\n'.join(p.extract_text() for p in pdf.pages)
        for valor in ('Relatório de acompanhamento', 'Clínica médica', '20/10/2026 08:30',
                      '0/10', 'Alergia demonstrativa', 'Levar o registro de sono', 'Relato registrado no diário.',
                      '72 bpm', '97%', 'Hemograma', 'Página 1'):
            self.assertIn(valor, texto)
        self.assertNotIn('nomeDoutor', texto)
        self.assertNotIn('dataHora', texto)
        self.assertNotIn('None', texto)

    def test_texto_longo_e_tabela_continuam_sem_perder_final(self):
        h = exemplo_historico()
        h['medicamentos'][0].descricao = ('Anotação extensa <sem marcação> & conteúdo preservado. ' * 200) + 'FINAL DA ORIENTAÇÃO'
        h['sinais_vitais'] = h['sinais_vitais'] * 85
        pdf = PdfReader(BytesIO(gerar_pdf_clinico(h)))
        texto = '\n'.join(p.extract_text() for p in pdf.pages)
        self.assertGreater(len(pdf.pages), 3)
        self.assertIn('FINAL DA ORIENTAÇÃO', texto)
        self.assertIn('<sem marcação>', texto)
        self.assertEqual(texto.count('120/80 mmHg'), 85)
        self.assertGreater(texto.count('Pressão'), 1)
        for numero, pagina in enumerate(pdf.pages, 1):
            self.assertIn(f'Página {numero}', pagina.extract_text())

    def test_periodo_sem_registros_nao_inventa_informacoes(self):
        h = exemplo_historico()
        for k in h:
            if isinstance(h[k], list):
                h[k] = []
        pdf = PdfReader(BytesIO(gerar_pdf_clinico(h)))
        texto = '\n'.join(p.extract_text() for p in pdf.pages)
        self.assertIn('Nenhum registro disponível.', texto)
        self.assertIn('Não há informação de alergias cadastrada.', texto)
