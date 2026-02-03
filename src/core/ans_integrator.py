import requests
import zipfile
import os
import re
import pandas as pd
from pathlib import Path
from bs4 import BeautifulSoup
from typing import List, Tuple
import logging

logger = logging.getLogger(__name__)

class ANSDataIntegrator:
    def __init__(self, base_url="https://dadosabertos.ans.gov.br/FTP/PDA/", 
                 raw_dir="data/raw", processed_dir="data/processed"):
        self.base_url = base_url
        self.raw_dir = Path(raw_dir)
        self.processed_dir = Path(processed_dir)
        self.raw_dir.mkdir(parents=True, exist_ok=True)
        self.processed_dir.mkdir(parents=True, exist_ok=True)
        
    def listar_trimestres(self):
        try:
            response = requests.get(self.base_url, timeout=30)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')
            anos = []
            for link in soup.find_all('a'):
                href = link.get('href', '')
                if re.match(r'^\d{4}/$', href):
                    anos.append(href.strip('/'))
            
            trimestres = []
            for ano in sorted(anos, reverse=True)[:2]:
                ano_url = f"{self.base_url}{ano}/"
                r = requests.get(ano_url, timeout=30)
                s = BeautifulSoup(r.text, 'html.parser')
                for link in s.find_all('a'):
                    href = link.get('href', '')
                    if re.match(r'^\dT/$', href):
                        trimestres.append((ano, href.strip('/')))
            return sorted(trimestres, reverse=True)[:3]
        except:
            return [("2024", "3T"), ("2024", "2T"), ("2024", "1T")]

    def baixar_arquivos(self, ano, trimestre):
        url = f"{self.base_url}{ano}/{trimestre}/"
        try:
            r = requests.get(url, timeout=30)
            soup = BeautifulSoup(r.text, 'html.parser')
            baixados = []
            for link in soup.find_all('a'):
                href = link.get('href', '')
                if href.endswith('.zip'):
                    f_url = url + href
                    f_path = self.raw_dir / f"{ano}_{trimestre}_{href}"
                    with open(f_path, 'wb') as f:
                        f.write(requests.get(f_url).content)
                    baixados.append(f_path)
            return baixados
        except:
            return []

    def processar_arquivos(self, trimestres):
        todos_dados = []
        for ano, tri in trimestres:
            arquivos = self.baixar_arquivos(ano, tri)
            for zip_p in arquivos:
                with zipfile.ZipFile(zip_p, 'r') as z:
                    temp_dir = self.raw_dir / "temp"
                    temp_dir.mkdir(exist_ok=True)
                    z.extractall(temp_dir)
                for f in (self.raw_dir / "temp").rglob('*'):
                    if f.suffix.lower() in ['.csv', '.xlsx']:
                        try:
                            df = pd.read_csv(f, sep=';', encoding='latin-1') if f.suffix == '.csv' else pd.read_excel(f)
                            df.columns = [c.upper() for c in df.columns]
                            cols = {'CNPJ': None, 'RAZAO': None, 'VALOR': None}
                            for c in df.columns:
                                if 'CNPJ' in c: cols['CNPJ'] = c
                                if 'RAZAO' in c or 'NOME' in c: cols['RAZAO'] = c
                                if 'VALOR' in c or 'DESPESA' in c: cols['VALOR'] = c
                            
                            if cols['CNPJ'] and cols['VALOR']:
                                res = df[[cols['CNPJ'], cols['VALOR']]].copy()
                                res.columns = ['CNPJ', 'ValorDespesas']
                                res['RazaoSocial'] = df[cols['RAZAO']] if cols['RAZAO'] else 'N/A'
                                res['Trimestre'] = tri
                                res['Ano'] = ano
                                todos_dados.append(res)
                        except:
                            continue
        
        if todos_dados:
            final = pd.concat(todos_dados)
            final.to_csv(self.processed_dir / "consolidado_despesas.csv", index=False)
            return True
        return False
