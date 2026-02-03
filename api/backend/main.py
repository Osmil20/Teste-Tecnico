from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
from pathlib import Path

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Operadora(BaseModel):
    cnpj: str
    razao_social: str
    registro_ans: Optional[str] = None
    modalidade: Optional[str] = None
    uf: Optional[str] = None

class PaginatedResponse(BaseModel):
    data: List[dict]
    total: int
    page: int
    limit: int

def load_data():
    base_path = Path(__file__).parent.parent.parent / "data" / "processed"
    p = base_path / "consolidado_despesas.csv"
    if p.exists():
        return pd.read_csv(p)
    return pd.DataFrame()

@app.get("/api/operadoras", response_model=PaginatedResponse)
async def list_ops(page: int = 1, limit: int = 10, search: str = None):
    df = load_data()
    if df.empty: return {"data": [], "total": 0, "page": page, "limit": limit}
    
    ops = df[['CNPJ', 'RazaoSocial']].drop_duplicates()
    if search:
        ops = ops[ops['RazaoSocial'].str.contains(search, case=False) | ops['CNPJ'].str.contains(search)]
    
    total = len(ops)
    start = (page - 1) * limit
    res = ops.iloc[start:start+limit].to_dict('records')
    
    return {
        "data": res,
        "total": total,
        "page": page,
        "limit": limit
    }

@app.get("/api/operadoras/{cnpj}")
async def get_op(cnpj: str):
    df = load_data()
    res = df[df['CNPJ'] == cnpj]
    if res.empty: raise HTTPException(status_code=404)
    return res.iloc[0].to_dict()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
