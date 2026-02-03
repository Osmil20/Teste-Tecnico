import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from src.core.ans_integrator import ANSDataIntegrator
import logging

logging.basicConfig(level=logging.INFO)

def main():
    integrator = ANSDataIntegrator(
        raw_dir="data/raw", 
        processed_dir="data/processed"
    )
    trimestres = integrator.listar_trimestres()
    if integrator.processar_arquivos(trimestres):
        print("Finalizado com sucesso.")
    else:
        print("Erro no processamento.")

if __name__ == "__main__":
    main()
