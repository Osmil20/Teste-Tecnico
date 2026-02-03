import pandas as pd
from pathlib import Path

def seed():
    out = Path("data/processed")
    out.mkdir(parents=True, exist_ok=True)
    
    data = {
        'CNPJ': ['12345678000190', '23456789000191', '34567890000192'],
        'RazaoSocial': ['UNIMED BH', 'AMIL SP', 'BRADESCO RJ'],
        'Trimestre': ['1T', '1T', '1T'],
        'Ano': [2024, 2024, 2024],
        'ValorDespesas': [150000.50, 280000.75, 450000.00]
    }
    
    pd.DataFrame(data).to_csv(out / "consolidado_despesas.csv", index=False)
    print("Dados gerados.")

if __name__ == "__main__":
    seed()
