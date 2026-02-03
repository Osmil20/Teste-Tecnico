import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from src.core.data_processor import DataProcessor

def main():
    processor = DataProcessor(
        input_path="data/processed/consolidado_despesas.csv",
        output_dir="data/processed"
    )
    if processor.executar_pipeline():
        print("Processamento concluido.")
    else:
        print("Arquivo de entrada nao encontrado.")

if __name__ == "__main__":
    main()
