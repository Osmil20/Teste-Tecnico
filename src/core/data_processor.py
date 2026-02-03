import pandas as pd
import re
from pathlib import Path

class DataProcessor:
    def __init__(self, input_path, output_dir):
        self.input_path = Path(input_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def validar_cnpj(self, cnpj):
        cnpj = re.sub(r'\D', '', str(cnpj))
        if len(cnpj) != 14 or cnpj == cnpj[0] * 14:
            return False
        
        def calc_digito(s, p):
            sm = sum(int(n) * m for n, m in zip(s, p))
            r = sm % 11
            return 0 if r < 2 else 11 - r

        p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
        p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
        
        d1 = calc_digito(cnpj[:12], p1)
        d2 = calc_digito(cnpj[:13], p2)
        
        return int(cnpj[12]) == d1 and int(cnpj[13]) == d2

    def executar_pipeline(self):
        if not self.input_path.exists():
            return False
            
        df = pd.read_csv(self.input_path)
        df['CNPJ'] = df['CNPJ'].astype(str).str.replace(r'\D', '', regex=True)
        df['CNPJ_Valido'] = df['CNPJ'].apply(self.validar_cnpj)
        
        df['ValorDespesas'] = pd.to_numeric(df['ValorDespesas'], errors='coerce').fillna(0)
        df.loc[df['ValorDespesas'] < 0, 'ValorDespesas'] = 0
        
        agregado = df.groupby(['RazaoSocial', 'Ano', 'Trimestre']).agg({
            'ValorDespesas': ['sum', 'mean', 'std', 'count']
        }).reset_index()
        
        agregado.columns = ['RazaoSocial', 'Ano', 'Trimestre', 'Total', 'Media', 'DesvioPadrao', 'Qtd']
        agregado.to_csv(self.output_dir / "despesas_agregadas.csv", index=False)
        return True
